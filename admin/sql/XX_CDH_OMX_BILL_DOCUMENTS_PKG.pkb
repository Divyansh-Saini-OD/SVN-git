CREATE OR REPLACE PACKAGE BODY APPS.XX_CDH_OMX_BILL_DOCUMENTS_PKG
AS
-- +================================================================================+
-- |                                                                                |
-- +================================================================================+
-- | Name  : XX_CDH_OMX_BILL_DOCUMENTS_PKG|
-- | Rice ID: C0700                                                                 |
-- | Description      : This Program will extract all the OMX Billing documents     |
-- |                    data received from OMX and creates the documents in oracle  |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version DATE        Author            Remarks                                   |
-- |======= =========== =============== ============================================|
-- |1.0     23-Feb-2015 Arun Gannarapu  Initial draft version                       |
-- |2.0     31-MAR-2015 Arun Gannarapu  Made changes to fix defect # 1004           |
-- |3.0     02-APR-2015 Arun Gannarapu  Made changes to fix defect # 1029           |
-- |4.0     09-APR-2015 Arun Gannarapu  Made changes to fix defect # 1075           |
-- |5.0     13-APR-2015 Arun Gannarapu  Made changes to fix defect # 1083 and 1082  |
-- |6.0     16-APR-2015 Arun Gannarapu  Made changes to fix defect # 1083 and 1118  |
-- |7.0	    07-MAY-2015 Arun Gannarapu  Made changes to fix defect # 1243           |
-- |8.0     13-MAY-2015 Arun Gannarapu  Made chagnes to fix defect # 1243           |
-- |9.0     20-MAY-2015 Arun Gannarapu  Made changes to fix defect # 1331           |
-- |10.0    06-Aug-2015 Arun Gannarapu  Made changes to fix the JavaNullpointer err |
-- +================================================================================+


  g_debug_flag      BOOLEAN;
  gc_success        VARCHAR2(100)   := 'SUCCESS';
  gc_failure        VARCHAR2(100)   := 'FAILURE';

  -- +===================================================================+
  -- | Name  : log_exception                                             |
  -- | Description     : The log_exception procedure logs all exceptions |
  -- |                                                                   |
  -- |                                                                   |
  -- | Parameters      : p_error_location     IN -> Error location       |
  -- |                   p_error_msg          IN -> Error message        |
  -- +===================================================================+

  PROCEDURE log_exception ( p_error_location     IN  VARCHAR2
                           ,p_error_msg          IN  VARCHAR2
                           ,p_program_id         IN  NUMBER DEFAULT NULL )
  IS
   --------------------------------
   -- Local Variable Declaration --
   --------------------------------
  ln_login     NUMBER                :=  FND_GLOBAL.LOGIN_ID;
  ln_user_id   NUMBER                :=  FND_GLOBAL.USER_ID;

  BEGIN
    XX_COM_ERROR_LOG_PUB.log_error(
                                     p_return_code             => FND_API.G_RET_STS_ERROR
                                    ,p_msg_count               => 1
                                    ,p_application_name        => 'XXCRM'
                                    ,p_program_type            => 'Custom Messages'
                                    ,p_program_name            => 'XX_CDH_OMX_BILL_DOCS_PKG'
                                    ,p_attribute15             => 'XX_CDH_OMX_BILL_DOCS_PKG'
                                    ,p_program_id              => null
                                    ,p_module_name             => 'MOD4A'
                                    ,p_error_location          => p_error_location
                                    ,p_error_message_code      => null
                                    ,p_error_message           => p_error_msg
                                    ,p_error_message_severity  => 'MAJOR'
                                    ,p_error_status            => 'ACTIVE'
                                    ,p_created_by              => ln_user_id
                                    ,p_last_upDATEd_by         => ln_user_id
                                    ,p_last_upDATE_login       => ln_login
                                    );

  EXCEPTION
    WHEN OTHERS
    THEN
      fnd_file.put_line(fnd_file.log, 'Error while writting to the log ...'|| SQLERRM);
  END log_exception;

  -- +===================================================================+
  -- | Name  : log_msg                                                   |
  -- | Description     : The log_msg procedure displays the log messages |
  -- |                                                                   |
  -- |                                                                   |
  -- | Parameters      : p_string             IN -> Log Message          |
  -- +===================================================================+

  PROCEDURE log_msg(
                    p_string IN VARCHAR2
                   )
  IS
  BEGIN
    IF (g_debug_flag)
    THEN
      fnd_file.put_line(fnd_file.LOG,p_string);
      dbms_output.put_line(p_string);
    END IF;
  END log_msg;

  -- +===================================================================+
  -- | Name  : get_customer_detais                                        |
  -- | Description     : This function returns the customer details       |
  -- |                   ret_orig_order_num for return orders             |
  -- |                                                                    |
  -- | Parameters      :                                                  |
  -- +===================================================================+

  FUNCTION get_customer_details(p_aops_cust_NUMBER IN  xx_cdh_omx_bill_docs_stg.aops_customer_NUMBER%TYPE,
                                p_customer_info    OUT hz_cust_accounts%ROWTYPE,
                                p_error_msg        OUT VARCHAR2)
  RETURN VARCHAR2
  IS
   BEGIN
     log_msg('Getting the customer details ..');
  
     p_error_msg := NULL;

     SELECT *
     INTO   p_customer_info
     FROM   hz_cust_accounts_all 
     WHERE  orig_system_reference = lpad(to_char(p_aops_cust_NUMBER),8,0)||'-'||'00001-A0';


     log_msg('cust acct id: ...:' ||p_customer_info.cust_account_id);

     RETURN gc_success;
   EXCEPTION
     WHEN NO_DATA_FOUND
     THEN
       p_error_msg := 'No Customer found for AOPS customer :'||p_aops_cust_NUMBER;
       fnd_file.put_line(fnd_file.log,p_error_msg);
       log_exception ( p_error_location    =>  'XX_CDH_OMX_BILL_DOCUMENTS_PKG.get_customer_details',
                       p_error_msg         =>  p_error_msg);
       RETURN gc_failure;
     WHEN OTHERS
     THEN
       p_error_msg := 'Unable to fetch Customer details :'||' '||SQLERRM;
       fnd_file.put_line(fnd_file.log,p_error_msg);
       log_exception ( p_error_location     =>  'XX_CDH_OMX_BILL_DOCUMENTS_PKG.get_customer_details'
                      ,p_error_msg          =>  p_error_msg);
       RETURN gc_failure;
  END get_customer_details;

  -- +===================================================================+
  -- | Name  : end_DATE_existing_doc                                     |
  -- | Description     : The function check if there are any active      |
  -- |                   docs exists for the given customer , if exists  |
  -- |                   it will end DATE all of them                    |
  -- |                                                                   |
  -- | Parameters      :                                                 |
  -- +===================================================================+
    
  FUNCTION end_date_existing_doc(p_aops_customer_NUMBER IN  xx_cdh_omx_bill_docs_stg.aops_customer_number%TYPE,
                                 p_cust_acct_id         IN  hz_cust_accounts_all.cust_account_id%TYPE,
                                 p_end_date             IN  DATE,
                                 p_error_msg            OUT VARCHAR2)
  RETURN VARCHAR2
  IS

  CURSOR cur_doc
  IS 
  SELECT *
  FROM xx_cdh_cust_acct_ext_b 
  WHERE cust_account_id = p_cust_acct_id 
  AND d_ext_attr2 IS NULL -- not end dated -- 
  AND p_end_date IS NOT NULL  
  AND ATTR_GROUP_ID = 166
  UNION
  SELECT *
  FROM xx_cdh_cust_acct_ext_b 
  WHERE cust_account_id = p_cust_acct_id 
  AND d_ext_attr2 IS NOT NULL -- not end dated -- 
  AND p_end_date IS NULL 
  AND ATTR_GROUP_ID = 166;

  ln_cnt NUMBER := 0;

  BEGIN
    p_error_msg := NULL;

    FOR cur_doc_rec IN cur_doc
    LOOP 
      BEGIN
        log_msg('End dating the document id .'|| cur_doc_rec.n_ext_Attr2);

        UPDATE XX_CDH_CUST_ACCT_EXT_B
        SET D_EXT_ATTR2 = p_end_Date -- SYSDATE-1 -- to_DATE('09/30/2014', 'MM/DD/YYYY'),  --end DATE
        WHERE  ATTR_GROUP_ID = 166
        AND N_EXT_ATTR2 = cur_doc_rec.n_ext_attr2;

        ln_cnt := ln_cnt + SQL%ROWCOUNT;
      END;
    END LOOP;  
    
    log_msg(ln_cnt ||' Rows End dated: ');

    RETURN gc_success;
  EXCEPTION
    WHEN OTHERS
    THEN
      p_error_msg := 'Error while end dating the docs'||SQLERRM;
      fnd_file.put_line(fnd_file.log,p_error_msg);
      log_exception ( p_error_location     =>  'XX_CDH_OMX_BILL_DOCUMENTS_PKG.end_DATE_existing_doc',
                      p_error_msg          =>  p_error_msg);
      RETURN gc_failure;
  END end_date_existing_doc;

  -- +===================================================================+
  -- | Name  : derive_billing_type                                       |
  -- | Description     : This function returns the billing  type          |
  -- |                                                                    |
  -- |                                                                    |
  -- | Parameters      :                                                  |
  -- +===================================================================+

  FUNCTION derive_billing_type(p_cursor_rec       IN  xx_cdh_omx_bill_docs_stg%ROWTYPE,
                               p_billing_type     OUT VARCHAR2,
                               p_error_msg        OUT VARCHAR2)
  RETURN VARCHAR2
  IS


  lc_success VARCHAR2(10) := 'S';
  lc_failure VARCHAR2(10) := 'F';

   BEGIN
     log_msg('deriving the billing type ..');
  
     p_error_msg     := NULL;

     SELECT billing_type
     INTO   p_billing_type
     FROM   xx_cdh_mod4_sfdc_cust_stg
     WHERE  aops_customer_NUMBER = p_cursor_rec.aops_customer_NUMBER;


     log_msg('Billing Type : '|| p_billing_type);

     RETURN gc_success;
   EXCEPTION
     WHEN NO_DATA_FOUND
     THEN
       p_error_msg := 'No Billing type found for customer :'||p_cursor_rec.aops_customer_NUMBER;
       fnd_file.put_line(fnd_file.log,p_error_msg);
       log_exception ( p_error_location    =>  'XX_CDH_OMX_BILL_DOCUMENTS_PKG.derive_billing_type',
                       p_error_msg         =>  p_error_msg);
       RETURN gc_failure;
     WHEN OTHERS
     THEN
       p_error_msg := 'Unable to fetch Billing type details :'||' '||SQLERRM;
       fnd_file.put_line(fnd_file.log,p_error_msg);
       log_exception (p_error_location     =>  'XX_CDH_OMX_BILL_DOCUMENTS_PKG.derive_billing_type',
                      p_error_msg          =>  p_error_msg);

       RETURN gc_failure;
  END derive_billing_type;

  -- +===================================================================+
  -- | Name  : get_translation_info                                       |
  -- | Description     : This function returns the transaltion info       |
  -- |                                                                    |
  -- |                                                                    |
  -- | Parameters      :                                                  |
  -- +===================================================================+

  FUNCTION get_translation_info(p_cursor_rec         IN  xx_cdh_omx_bill_docs_stg%ROWTYPE,
                                p_translation_info   OUT xx_fin_translatevalues%ROWTYPE,
                                p_default_used       OUT VARCHAR2,
                                p_error_msg          OUT VARCHAR2)
  RETURN VARCHAR2
  IS

  lc_translation_name        xx_fin_translatedefinition.translation_name%TYPE := 'XXOD_MOD4_OMX_BILLING_INF';

  e_process_exception        EXCEPTION;

--

   BEGIN

     p_default_used     := NULL; 
     p_error_msg        := NULL;
     p_translation_info := NULL;

 
     log_msg('Summary Bill      :'|| p_cursor_rec.summary_bill_flag);
     log_msg('Print daily       :'|| p_cursor_rec.print_daily_flag);
     log_msg('print Exp Report  :'|| p_cursor_rec.print_exp_rep_flag);
     log_msg('print inv detail  :'|| p_cursor_rec.print_inv_detail_flag);
     log_msg('print remit page  :'|| p_cursor_rec.print_remittance_page);
     log_msg('cons sort by exp  :'|| p_cursor_rec.sort_by_consignee_exp_rpt);
     log_msg('po sory by exp    :'|| p_cursor_rec.sort_by_po_exp_rpt);
     log_msg('cc sory by exp    :'|| p_cursor_rec.sort_by_costcenter_exp_rpt);
  

     SELECT xftv.*
     INTO p_translation_info
     FROM xx_fin_translatedefinition xft,
          xx_fin_translatevalues xftv
     WHERE xft.translate_id    = xftv.translate_id
     AND xft.enabled_flag      = 'Y'
     AND xftv.enabled_flag     = 'Y'
     AND xft.translation_name  = lc_translation_name
     AND xftv.source_value2    = NVL(p_cursor_rec.summary_bill_flag, 'N')
     AND xftv.source_value3    = NVL(p_cursor_rec.print_daily_flag, 'N')
     AND xftv.source_value4    = NVL(p_cursor_rec.print_exp_rep_flag, 'N')
     AND xftv.source_value5    = NVL(p_cursor_rec.print_inv_detail_flag, 'N')
     AND xftv.source_value6    = NVL(p_cursor_rec.print_remittance_page, 'N')
     AND xftv.source_value7    = NVL(p_cursor_rec.sort_by_consignee_exp_rpt, 'N')
     AND xftv.source_value8    = NVL(p_cursor_rec.sort_by_costcenter_exp_rpt, 'N')
     AND xftv.source_value9    = NVL(p_cursor_rec.sort_by_po_exp_rpt, 'N');

     log_msg('Translate Id :'|| p_translation_info.translate_id);

     RETURN gc_success;
   EXCEPTION
     WHEN NO_DATA_FOUND
     THEN
       p_error_msg := 'No Translation info found for given ODN values for customer :'||p_cursor_rec.aops_customer_number ;
       fnd_file.put_line(fnd_file.log,p_error_msg);

       log_msg('Deriving the default values for MBS Doc id and Document type..');

       BEGIN 
         SELECT xftv.*
         INTO p_translation_info
         FROM xx_fin_translatedefinition xft,
              xx_fin_translatevalues xftv
         WHERE xft.translate_id  = xftv.translate_id
         AND xft.enabled_flag    = 'Y'
         AND xftv.enabled_flag   = 'Y'
         AND translation_name    = lc_translation_name
         AND source_Value1       = 'DEFAULT';

         p_default_used := 'Y';

         log_msg('Default Translate Id :'|| p_translation_info.translate_id);

       EXCEPTION 
         WHEN NO_DATA_FOUND 
         THEN 
           p_error_msg := 'No Translation info found for customer :'||p_cursor_rec.aops_customer_number ;
           RAISE e_process_exception;
         WHEN OTHERS 
         THEN 
           RAISE e_process_exception;
       END;
 
       RETURN gc_success;
     WHEN OTHERS
     THEN
       IF p_error_msg IS NULL 
       THEN
         p_error_msg := 'Unable to fetch Customer details :'||' '||SQLERRM;
       END IF;
       fnd_file.put_line(fnd_file.log,p_error_msg);
       log_exception ( p_error_location     =>  'XX_CDH_OMX_BILL_DOCUMENTS_PKG.get_Translation_info'
                      ,p_error_msg          =>  p_error_msg);
       RETURN gc_failure;
  END get_translation_info;

  -- +===================================================================+
  -- | Name  : get_payment_term_info                                      |
  -- | Description     : This function returns the payment terminfo       |
  -- |                                                                    |
  -- |                                                                    |
  -- | Parameters      :                                                  |
  -- +===================================================================+

  FUNCTION get_payment_term_info(p_cursor_rec          IN  xx_cdh_omx_bill_docs_stg%ROWTYPE,
                                 p_doc_type            IN  xx_fin_translatevalues.target_value2%TYPE,
                                 p_payment_term_info   OUT ra_terms%ROWTYPE,
                                 p_default_used        OUT VARCHAR2,
                                 p_error_msg           OUT VARCHAR2)
  RETURN VARCHAR2
  IS

  lc_payterm_info          xx_fin_translatevalues%ROWTYPE;
  lc_summary_bill_cycle    VARCHAR2(10) := NULL;

  e_process_exception  EXCEPTION;

  BEGIN 
    BEGIN
      p_error_msg          := NULL;
      p_payment_term_info  := NULL;
      p_default_used       := NULL;

      log_msg('ODN Payment term :'|| p_cursor_rec.payment_term);
      log_msg('Cycle            :'|| p_cursor_rec.summary_bill_cycle);
      log_msg('P_doc_type       :'|| p_doc_type);
 
      log_msg('Getting Payment term info  ..');

     /* IF p_cursor_rec.print_daily_flag != 'N'
      THEN
        lc_summary_bill_Cycle := 'D';
      ELSE
        lc_summary_bill_Cycle := p_cursor_rec.summary_bill_Cycle;
      END IF; */

      IF p_doc_type = 'Consolidated Bill'
      THEN
        lc_summary_bill_Cycle := p_cursor_rec.summary_bill_Cycle;
      ELSE
        lc_summary_bill_Cycle := 'D';
      END IF;

      log_msg('Summary bill Cycle            :'|| lc_summary_bill_cycle);

      SELECT xftv.*
      INTO lc_payterm_info
      FROM xx_fin_translatedefinition xft,
           xx_fin_translatevalues xftv,
           ra_terms rt
      WHERE xft.translate_id  = xftv.translate_id
      AND xft.enabled_flag    = 'Y'
      AND xftv.enabled_flag   = 'Y'
      AND translation_name    = 'XXOD_OMX_PAYMENT_TERMS'
      AND xftv.source_value3  =  lc_summary_bill_cycle 
      AND rt.name             =  xftv.target_value1
      AND NVL(rt.end_date_active, SYSDATE) >= SYSDATE
      AND xftv.source_value1  =  p_cursor_rec.payment_term;

      log_msg('ODN Payment term Name : '|| lc_payterm_info.target_Value1);

    EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
        p_error_msg := 'No payment term info found for given ODN payterm '||lc_payterm_info.target_Value1 ;
        fnd_file.put_line(fnd_file.log,p_error_msg);

        log_msg('Deriving the default payment term value..');

        BEGIN 
          SELECT xftv.*
          INTO lc_payterm_info
          FROM xx_fin_translatedefinition xft,
               xx_fin_translatevalues xftv
          WHERE xft.translate_id  = xftv.translate_id
          AND xft.enabled_flag    = 'Y'
          AND xftv.enabled_flag   = 'Y'
          AND translation_name    = 'XXOD_OMX_PAYMENT_TERMS'
          AND xftv.source_Value1  = 'DEFAULT';

          p_default_used := 'Y';

        EXCEPTION 
          WHEN NO_DATA_FOUND 
          THEN 
            p_error_msg := 'No default payment term info found for customer :'||p_cursor_rec.aops_customer_number ;
            fnd_file.put_line(fnd_file.log,p_error_msg);
            RAISE e_process_exception;
          WHEN OTHERS 
          THEN 
            RAISE e_process_exception;
        END;
      WHEN OTHERS
      THEN
        IF p_error_msg IS NULL
        THEN
          p_error_msg := 'Unable to fetch payment term details :'||' '||SQLERRM;
        END IF;

        fnd_file.put_line(fnd_file.log,p_error_msg);
        log_exception ( p_error_location     =>  'XX_CDH_OMX_BILL_DOCUMENTS_PKG.get_paymente_Term_info'
                       ,p_error_msg          =>  p_error_msg);
        RETURN gc_failure;
      END ; 
  
      -- Get Oracle payment term ..
      IF lc_payterm_info.target_Value1 IS NOT NULL
      THEN 
        BEGIN
          SELECT *
          INTO p_payment_term_info
          FROM ra_terms 
          WHERE name = lc_payterm_info.target_value1 
          AND NVL(end_date_active, SYSDATE) >= SYSDATE;

          log_msg( 'Payment term id :' || p_payment_term_info.term_id);    
          log_msg( 'payment term name :' || p_payment_term_info.name); 
        EXCEPTION 
          WHEN NO_DATA_FOUND 
          THEN 
            p_error_msg := 'NO payment term found for mapped Oracle Payment term :'||lc_payterm_info.target_value1;
            RAISE e_process_exception;
           WHEN OTHERS 
           THEN 
             p_error_msg := 'Error while getting payment term info '|| SQLERRM ;
             RAISE e_process_exception;
        END;
      END IF;     
    

    RETURN gc_success;

  EXCEPTION 
    WHEN OTHERS 
    THEN 
      IF p_error_msg IS NULL
      THEN
        p_error_msg := 'Unable to fetch payment term details :'||' '||SQLERRM;
      END IF;

      fnd_file.put_line(fnd_file.log,p_error_msg);
      log_exception ( p_error_location     =>  'XX_CDH_OMX_BILL_DOCUMENTS_PKG.get_paymente_Term_info'
                     ,p_error_msg          =>  p_error_msg);
      RETURN gc_failure;

  END get_payment_term_info;


  -- +===================================================================+
  -- | Name  : derive_delivery_method                                     |
  -- | Description     : This function returns the delivery method info   |
  -- |                                                                    |
  -- |                                                                    |
  -- | Parameters      :                                                  |
  -- +===================================================================+

  FUNCTION derive_delivery_method(p_billing_flag        IN  xx_cdh_omx_bill_docs_Stg.summary_bill_flag%TYPE,
                                  p_delivery_method     OUT VARCHAR2,
                                  p_default_used        OUT VARCHAR2,
                                  p_error_msg           OUT VARCHAR2)
  RETURN VARCHAR2
  IS

  lc_transalation_name xx_fin_translatedefinition.translation_name%TYPE := 'XXOD_MOD4_OMX_DEL_METHOD';

  e_process_exception     EXCEPTION;

  BEGIN 
    BEGIN
      p_error_msg          := NULL;
      p_delivery_method    := NULL;
      p_default_used       := NULL;

      log_msg('Billing flag      :'|| p_billing_flag);
 
      SELECT xftv.target_value1
      INTO p_delivery_method
      FROM xx_fin_translatedefinition xft,
           xx_fin_translatevalues xftv
      WHERE xft.translate_id  = xftv.translate_id
      AND xft.enabled_flag    = 'Y'
      AND xftv.enabled_flag   = 'Y'
      AND translation_name    =  lc_transalation_name 
      AND xftv.source_value1  =  p_billing_flag;

      log_msg('ODN delivery method : '|| p_delivery_method);
        
    EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
        p_error_msg := 'No delivery method info found for given billing flag :'||p_billing_flag;
        fnd_file.put_line(fnd_file.log,p_error_msg);

        log_msg('Deriving the default delivery method value..');

        BEGIN 
          SELECT xftv.target_value1
          INTO p_delivery_method
          FROM xx_fin_translatedefinition xft,
               xx_fin_translatevalues xftv
          WHERE xft.translate_id  = xftv.translate_id
          AND xft.enabled_flag    = 'Y'
          AND xftv.enabled_flag   = 'Y'
          AND translation_name    = lc_transalation_name 
          AND xftv.source_Value1  = 'DEFAULT';

          p_default_used  := 'Y';
   
          log_msg('Default Delivery method: '|| p_delivery_method);

        EXCEPTION 
          WHEN NO_DATA_FOUND 
          THEN 
            p_error_msg := 'No default delivery method found for given billing flag :'||p_billing_flag ;
            RAISE e_process_exception;
            fnd_file.put_line(fnd_file.log,p_error_msg);
          WHEN OTHERS 
          THEN 
            RAISE e_process_exception;
        END;
      
      WHEN OTHERS
      THEN
        IF p_error_msg IS NULL
        THEN
          p_error_msg := 'Unable to derive delivery method :'||' '||SQLERRM;
        END IF;

        fnd_file.put_line(fnd_file.log,p_error_msg);
        log_exception ( p_error_location     =>  'XX_CDH_OMX_BILL_DOCUMENTS_PKG.derive_delivery_method'
                       ,p_error_msg          =>  p_error_msg);
        RETURN gc_failure;
    END ; 
   RETURN gc_success;
  END derive_delivery_method;


  -- +========================================================================================+
  -- | Name  : Build Extension table                                                          |
  -- | Description   : This Procedure This process will build the                             |
  -- |                 attribute_data_table and attribute_row_table based                     |
  -- |                 on the values provided . These row tables are needed for API call.     |
  -- |                 EGO_USER_ATTRS_DATA_PUB.Process_User_Attrs_Data to create the document |
  -- |                                                                                        |
  -- |                                                                                        |
  -- | Parameters    :                                                                        |
  -- +========================================================================================+

  PROCEDURE build_extension_table(p_user_row_table  IN OUT EGO_USER_ATTR_ROW_TABLE,
                                  p_user_data_table IN OUT EGO_USER_ATTR_DATA_TABLE,
                                  p_ext_attribs_row IN OUT xx_od_ext_attr_rec,
                                  p_return_Status       OUT VARCHAR2,
                                  p_error_msg           OUT VARCHAR2)
  IS

  --Retrieve Attribute Group id based on the Attribute Group code and
  -- Flexfleid Name

  CURSOR c_ego_attr_grp_id ( p_flexfleid_name VARCHAR2, p_context_code VARCHAR2)
  IS
  SELECT attr_group_id
  FROM   ego_fnd_dsc_flx_ctx_ext
  WHERE  descriptive_flexfield_name    = p_flexfleid_name
  AND    descriptive_flex_context_code = p_context_code;

  --
  CURSOR c_ext_attr_name( p_flexfleid_name VARCHAR2, p_context_code VARCHAR2)
  IS
  SELECT *
  FROM   fnd_descr_flex_column_usages
  WHERE  descriptive_flexfield_name    = p_flexfleid_name
  AND    descriptive_flex_context_code = p_context_code
  AND    enabled_flag                  = 'Y';

  TYPE l_xxod_ext_attribs_stg          IS TABLE OF c_ext_attr_name%ROWTYPE INDEX BY BINARY_INTEGER;
  lx_od_ext_attrib_stg                 l_xxod_ext_attribs_stg;

  lc_row_temp_obj                      EGO_USER_ATTR_ROW_OBJ :=
                                       EGO_USER_ATTR_ROW_OBJ(null,null,null,null,null,null,null,null,null,null,null,null); -- Edited for R12 retrofit (25-JUN-2013)

  lc_data_temp_obj                     EGO_USER_ATTR_DATA_OBJ:=
                                       EGO_USER_ATTR_DATA_OBJ(null,null,null,null,null,null,null,null);
  lc_count                             NUMBER := 1;
  l_flexfleid_name                     VARCHAR2(50);
  l_attr_group_id                      NUMBER;
  lc_exception                         EXCEPTION;
  j                                    PLS_INTEGER :=0;


  e_process_exception     EXCEPTION;

  BEGIN 
  

    IF p_ext_attribs_row.interface_entity_name    = XX_CDH_OMX_BILL_DOCUMENTS_PKG.G_PERSON
    THEN
      l_flexfleid_name:='HZ_PERSON_PROFILES_GROUP';
    ELSIF p_ext_attribs_row.interface_entity_name = XX_CDH_OMX_BILL_DOCUMENTS_PKG.G_ORGANIZATION
    THEN
      l_flexfleid_name:='HZ_ORG_PROFILES_GROUP';
    ELSIF p_ext_attribs_row.interface_entity_name = XX_CDH_OMX_BILL_DOCUMENTS_PKG.G_SITE
    THEN
      l_flexfleid_name:='HZ_PARTY_SITES_GROUP';
    ELSIF p_ext_attribs_row.interface_entity_name = XX_CDH_OMX_BILL_DOCUMENTS_PKG.G_ACCOUNT
    THEN
      l_flexfleid_name:='XX_CDH_CUST_ACCOUNT';
    ELSIF p_ext_attribs_row.interface_entity_name = XX_CDH_OMX_BILL_DOCUMENTS_PKG.G_ACC_SITE
    THEN
      l_flexfleid_name:='XX_CDH_CUST_ACCT_SITE';
    ELSIF p_ext_attribs_row.interface_entity_name = XX_CDH_OMX_BILL_DOCUMENTS_PKG.G_ACC_SITE_USE
    THEN
      l_flexfleid_name:='XX_CDH_ACCT_SITE_USES';
    END IF;


    OPEN  c_ego_attr_grp_id (l_flexfleid_name,p_ext_attribs_row.ATTRIBUTE_GROUP_CODE);
    FETCH c_ego_attr_grp_id INTO l_attr_group_id;
    CLOSE c_ego_attr_grp_id;

    IF l_attr_group_id IS NULL
    THEN
      p_error_msg := 'Extensible Attribute: '||INITCAP(p_ext_attribs_row.interface_entity_name)||
                          ' Attribute Group Id is null';
      RAISE e_process_exception;
    END IF;
    
    OPEN  c_ext_attr_name(l_flexfleid_name,p_ext_attribs_row.ATTRIBUTE_GROUP_CODE);
    FETCH c_ext_attr_name BULK COLLECT INTO lx_od_ext_attrib_stg;
    CLOSE c_ext_attr_name;

    p_user_row_table.extend;
    p_user_row_table(1)                  := lc_row_temp_obj;
    p_user_row_table(1).row_identifier   := p_ext_attribs_row.record_id;
    p_user_row_table(1).attr_group_id    := l_attr_group_id;
    p_user_row_table(1).transaction_type := ego_user_attrs_data_pvt.g_sync_mode;


    FOR i IN 1 .. lx_od_ext_attrib_stg.COUNT
    LOOP
      -------------------------
      -- Character Attributes
      ------------------------
      
      IF lx_od_ext_attrib_stg(i).application_column_name ='C_EXT_ATTR1'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr1) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;

          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr1) = FND_API.G_MISS_CHAR THEN
            p_user_data_table(j).attr_value_str := NULL;
          ELSE
            p_user_data_table(j).attr_value_str := p_ext_attribs_row.c_ext_attr1;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='C_EXT_ATTR2'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr2) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;
 
          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr2) = FND_API.G_MISS_CHAR
          THEN
            p_user_data_table(j).attr_value_str := NULL;
          ELSE
            p_user_data_table(j).attr_value_str := p_ext_attribs_row.c_ext_attr2;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='C_EXT_ATTR3'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr3) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;
 
          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr3) = FND_API.G_MISS_CHAR
          THEN
            p_user_data_table(j).attr_value_str := NULL;
          ELSE
            p_user_data_table(j).attr_value_str := p_ext_attribs_row.c_ext_attr3;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='C_EXT_ATTR4'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr4) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;
 
          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr4) = FND_API.G_MISS_CHAR
          THEN
            p_user_data_table(j).attr_value_str := NULL;
          ELSE
            p_user_data_table(j).attr_value_str := p_ext_attribs_row.c_ext_attr4;
          END IF;
        END IF;
                
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='C_EXT_ATTR5'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr5) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;

          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr5) = FND_API.G_MISS_CHAR
          THEN
            p_user_data_table(j).attr_value_str := NULL;
          ELSE
            p_user_data_table(j).attr_value_str := p_ext_attribs_row.c_ext_attr5;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='C_EXT_ATTR6'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr6) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;

          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr6) = FND_API.G_MISS_CHAR
          THEN
            p_user_data_table(j).attr_value_str := NULL;
          ELSE
            p_user_data_table(j).attr_value_str := p_ext_attribs_row.c_ext_attr6;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='C_EXT_ATTR7'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr7) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;
 
          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr7) = FND_API.G_MISS_CHAR
          THEN
            p_user_data_table(j).attr_value_str := NULL;
          ELSE
            p_user_data_table(j).attr_value_str := p_ext_attribs_row.c_ext_attr7;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='C_EXT_ATTR8'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr8) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;

          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr8) = FND_API.G_MISS_CHAR
          THEN
            p_user_data_table(j).attr_value_str := NULL;
          ELSE
            p_user_data_table(j).attr_value_str := p_ext_attribs_row.c_ext_attr8;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='C_EXT_ATTR9'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr9) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;
 
          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr9) = FND_API.G_MISS_CHAR
          THEN
            p_user_data_table(j).attr_value_str := NULL;
          ELSE
            p_user_data_table(j).attr_value_str := p_ext_attribs_row.c_ext_attr9;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='C_EXT_ATTR10'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr10) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;

          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr10) = FND_API.G_MISS_CHAR
          THEN
            p_user_data_table(j).attr_value_str := NULL;
          ELSE
            p_user_data_table(j).attr_value_str := p_ext_attribs_row.c_ext_attr10;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='C_EXT_ATTR11'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr11) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;

          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr11) = FND_API.G_MISS_CHAR
          THEN
            p_user_data_table(j).attr_value_str := NULL;
          ELSE
            p_user_data_table(j).attr_value_str := p_ext_attribs_row.c_ext_attr11;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='C_EXT_ATTR12'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr12) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;

          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr12) = FND_API.G_MISS_CHAR
          THEN
            p_user_data_table(j).attr_value_str := NULL;
          ELSE
            p_user_data_table(j).attr_value_str := p_ext_attribs_row.c_ext_attr12;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='C_EXT_ATTR13'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr13) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;

          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr13) = FND_API.G_MISS_CHAR
          THEN
            p_user_data_table(j).attr_value_str := NULL;
          ELSE
            p_user_data_table(j).attr_value_str := p_ext_attribs_row.c_ext_attr13;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='C_EXT_ATTR14'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr14) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;
 
          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr14) = FND_API.G_MISS_CHAR
          THEN
            p_user_data_table(j).attr_value_str := NULL;
          ELSE
            p_user_data_table(j).attr_value_str := p_ext_attribs_row.c_ext_attr14;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='C_EXT_ATTR15'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr15) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;
 
          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr15) = FND_API.G_MISS_CHAR
          THEN
            p_user_data_table(j).attr_value_str := NULL;
          ELSE
            p_user_data_table(j).attr_value_str := p_ext_attribs_row.c_ext_attr15;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='C_EXT_ATTR16'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr16) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;

          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr16) = FND_API.G_MISS_CHAR
          THEN
            p_user_data_table(j).attr_value_str := NULL;
          ELSE
            p_user_data_table(j).attr_value_str := p_ext_attribs_row.c_ext_attr16;
          END IF;
        END IF;
      
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='C_EXT_ATTR17'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr17) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;

          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr17) = FND_API.G_MISS_CHAR
          THEN
            p_user_data_table(j).attr_value_str := NULL;
          ELSE
            p_user_data_table(j).attr_value_str := p_ext_attribs_row.c_ext_attr17;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='C_EXT_ATTR18'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr18) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;

          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr18) = FND_API.G_MISS_CHAR
          THEN
            p_user_data_table(j).attr_value_str := NULL;
          ELSE
            p_user_data_table(j).attr_value_str := p_ext_attribs_row.c_ext_attr18;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='C_EXT_ATTR19'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr19) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;

          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr19) = FND_API.G_MISS_CHAR
          THEN
            p_user_data_table(j).attr_value_str := NULL;
          ELSE
            p_user_data_table(j).attr_value_str := p_ext_attribs_row.c_ext_attr19;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='C_EXT_ATTR20'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr20) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;
 
          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(p_ext_attribs_row.c_ext_attr20) = FND_API.G_MISS_CHAR
          THEN
            p_user_data_table(j).attr_value_str := NULL;
          ELSE
            p_user_data_table(j).attr_value_str := p_ext_attribs_row.c_ext_attr20;
          END IF;
        END IF;

     -------------------------
     -- NUMBER Attributes
     -------------------------
            
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='N_EXT_ATTR1'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr1) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;

          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr1) = FND_API.G_MISS_NUM
          THEN
            p_user_data_table(j).attr_value_num := NULL;
          ELSE
            p_user_data_table(j).attr_value_num := p_ext_attribs_row.n_ext_attr1;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='N_EXT_ATTR2'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr2) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;

          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr2) = FND_API.G_MISS_NUM
          THEN
            p_user_data_table(j).attr_value_num := NULL;
          ELSE
            p_user_data_table(j).attr_value_num := p_ext_attribs_row.n_ext_attr2;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='N_EXT_ATTR3'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr3) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;
 
          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr3) = FND_API.G_MISS_NUM
          THEN
            p_user_data_table(j).attr_value_num := NULL;
          ELSE
            p_user_data_table(j).attr_value_num := p_ext_attribs_row.n_ext_attr3;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='N_EXT_ATTR4'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr4) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;

          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr4) = FND_API.G_MISS_NUM
          THEN
            p_user_data_table(j).attr_value_num := NULL;
          ELSE
            p_user_data_table(j).attr_value_num := p_ext_attribs_row.n_ext_attr4;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='N_EXT_ATTR5'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr5) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;
 
          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr5) = FND_API.G_MISS_NUM
          THEN
            p_user_data_table(j).attr_value_num := NULL;
          ELSE
            p_user_data_table(j).attr_value_num := p_ext_attribs_row.n_ext_attr5;
          END IF;
        END IF;
        
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='N_EXT_ATTR6'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr6) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;
 
          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr6) = FND_API.G_MISS_NUM
          THEN
            p_user_data_table(j).attr_value_num := NULL;
          ELSE
            p_user_data_table(j).attr_value_num := p_ext_attribs_row.n_ext_attr6;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='N_EXT_ATTR7'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr7) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;
 
          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr7) = FND_API.G_MISS_NUM
          THEN
            p_user_data_table(j).attr_value_num := NULL;
          ELSE
            p_user_data_table(j).attr_value_num := p_ext_attribs_row.n_ext_attr7;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='N_EXT_ATTR8'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr8) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;
 
          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr8) = FND_API.G_MISS_NUM
          THEN
            p_user_data_table(j).attr_value_num := NULL;
          ELSE
            p_user_data_table(j).attr_value_num := p_ext_attribs_row.n_ext_attr8;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='N_EXT_ATTR9'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr9) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;

          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr9) = FND_API.G_MISS_NUM
          THEN
            p_user_data_table(j).attr_value_num := NULL;
          ELSE
            p_user_data_table(j).attr_value_num := p_ext_attribs_row.n_ext_attr9;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='N_EXT_ATTR10'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr10) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;
 
          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr10) = FND_API.G_MISS_NUM
          THEN
            p_user_data_table(j).attr_value_num := NULL;
          ELSE
            p_user_data_table(j).attr_value_num := p_ext_attribs_row.n_ext_attr10;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='N_EXT_ATTR11'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr11) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;

          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr11) = FND_API.G_MISS_NUM
          THEN
            p_user_data_table(j).attr_value_num := NULL;
          ELSE
            p_user_data_table(j).attr_value_num := p_ext_attribs_row.n_ext_attr11;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='N_EXT_ATTR12'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr12) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;
 
          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr12) = FND_API.G_MISS_NUM
          THEN
            p_user_data_table(j).attr_value_num := NULL;
          ELSE
            p_user_data_table(j).attr_value_num := p_ext_attribs_row.n_ext_attr12;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='N_EXT_ATTR13'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr13) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;
 
          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr13) = FND_API.G_MISS_NUM
          THEN
            p_user_data_table(j).attr_value_num := NULL;
          ELSE
            p_user_data_table(j).attr_value_num := p_ext_attribs_row.n_ext_attr13;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='N_EXT_ATTR14'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr14) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;
 
          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr14) = FND_API.G_MISS_NUM
          THEN
            p_user_data_table(j).attr_value_num := NULL;
          ELSE
            p_user_data_table(j).attr_value_num := p_ext_attribs_row.n_ext_attr14;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='N_EXT_ATTR15'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr15) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;
 
          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr15) = FND_API.G_MISS_NUM
          THEN
            p_user_data_table(j).attr_value_num := NULL;
          ELSE
            p_user_data_table(j).attr_value_num := p_ext_attribs_row.n_ext_attr15;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='N_EXT_ATTR16'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr16) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;
 
          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr16) = FND_API.G_MISS_NUM
          THEN
            p_user_data_table(j).attr_value_num := NULL;
          ELSE
            p_user_data_table(j).attr_value_num := p_ext_attribs_row.n_ext_attr16;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='N_EXT_ATTR17'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr17) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;
 
          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr17) = FND_API.G_MISS_NUM
          THEN
            p_user_data_table(j).attr_value_num := NULL;
          ELSE
            p_user_data_table(j).attr_value_num := p_ext_attribs_row.n_ext_attr17;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='N_EXT_ATTR18'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr18) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;

          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr18) = FND_API.G_MISS_NUM
          THEN
            p_user_data_table(j).attr_value_num := NULL;
          ELSE
            p_user_data_table(j).attr_value_num := p_ext_attribs_row.n_ext_attr18;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='N_EXT_ATTR19'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr19) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;
 
          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr19) = FND_API.G_MISS_NUM
          THEN
            p_user_data_table(j).attr_value_num := NULL;
          ELSE
            p_user_data_table(j).attr_value_num := p_ext_attribs_row.n_ext_attr19;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='N_EXT_ATTR20'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr20) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;
 
          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(p_ext_attribs_row.n_ext_attr20) = FND_API.G_MISS_NUM
          THEN
            p_user_data_table(j).attr_value_num := NULL;
          ELSE
            p_user_data_table(j).attr_value_num := p_ext_attribs_row.n_ext_attr20;
          END IF;
        END IF;

      -------------------------
      -- DATE Attributes
      -------------------------
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='D_EXT_ATTR1'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_DATE(p_ext_attribs_row.d_ext_attr1) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;
 
          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_DATE(p_ext_attribs_row.d_ext_attr1) = FND_API.G_MISS_DATE
          THEN
            p_user_data_table(j).attr_value_DATE := NULL;
          ELSE
            p_user_data_table(j).attr_value_DATE := p_ext_attribs_row.d_ext_attr1;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='D_EXT_ATTR2'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_DATE(p_ext_attribs_row.d_ext_attr2) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;

          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_DATE(p_ext_attribs_row.d_ext_attr2) = FND_API.G_MISS_DATE
          THEN
            p_user_data_table(j).attr_value_DATE := NULL;
          ELSE
            p_user_data_table(j).attr_value_DATE := p_ext_attribs_row.d_ext_attr2;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='D_EXT_ATTR3'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_DATE(p_ext_attribs_row.d_ext_attr3) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;
 
          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_DATE(p_ext_attribs_row.d_ext_attr3) = FND_API.G_MISS_DATE
          THEN
            p_user_data_table(j).attr_value_DATE := NULL;
          ELSE
             p_user_data_table(j).attr_value_DATE := p_ext_attribs_row.d_ext_attr3;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='D_EXT_ATTR4'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_DATE(p_ext_attribs_row.d_ext_attr4) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;
 
          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_DATE(p_ext_attribs_row.d_ext_attr4) = FND_API.G_MISS_DATE
          THEN
            p_user_data_table(j).attr_value_DATE := NULL;
          ELSE
            p_user_data_table(j).attr_value_DATE := p_ext_attribs_row.d_ext_attr4;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='D_EXT_ATTR5'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_DATE(p_ext_attribs_row.d_ext_attr5) IS NULL
        THEN
         NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;
 
          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_DATE(p_ext_attribs_row.d_ext_attr5) = FND_API.G_MISS_DATE
          THEN
            p_user_data_table(j).attr_value_DATE := NULL;
          ELSE
            p_user_data_table(j).attr_value_DATE := p_ext_attribs_row.d_ext_attr5;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='D_EXT_ATTR6'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_DATE(p_ext_attribs_row.d_ext_attr6) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;

          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_DATE(p_ext_attribs_row.d_ext_attr6) = FND_API.G_MISS_DATE
          THEN
            p_user_data_table(j).attr_value_DATE := NULL;
          ELSE
            p_user_data_table(j).attr_value_DATE := p_ext_attribs_row.d_ext_attr6;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='D_EXT_ATTR7'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_DATE(p_ext_attribs_row.d_ext_attr7) IS NULL
        THEN
         NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;

          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_DATE(p_ext_attribs_row.d_ext_attr7) = FND_API.G_MISS_DATE 
          THEN
            p_user_data_table(j).attr_value_DATE := NULL;
          ELSE
            p_user_data_table(j).attr_value_DATE := p_ext_attribs_row.d_ext_attr7;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='D_EXT_ATTR8'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_DATE(p_ext_attribs_row.d_ext_attr8) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;
 
          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_DATE(p_ext_attribs_row.d_ext_attr8) = FND_API.G_MISS_DATE
          THEN
            p_user_data_table(j).attr_value_DATE := NULL;
          ELSE
            p_user_data_table(j).attr_value_DATE := p_ext_attribs_row.d_ext_attr8;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='D_EXT_ATTR9'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_DATE(p_ext_attribs_row.d_ext_attr9) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;
 
          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_DATE(p_ext_attribs_row.d_ext_attr9) = FND_API.G_MISS_DATE
          THEN
            p_user_data_table(j).attr_value_DATE := NULL;
          ELSE
            p_user_data_table(j).attr_value_DATE := p_ext_attribs_row.d_ext_attr9;
          END IF;
        END IF;
      ELSIF lx_od_ext_attrib_stg(i).application_column_name ='D_EXT_ATTR10'
      THEN
        IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_DATE(p_ext_attribs_row.d_ext_attr10) IS NULL
        THEN
          NULL;
        ELSE
          p_user_data_table.extend;
          j                                   := j+1;
          p_user_data_table(j)                := lc_data_temp_obj;
          p_user_data_table(j).row_identifier := p_ext_attribs_row.record_id;
          p_user_data_table(j).attr_name      := lx_od_ext_attrib_stg(i).end_user_column_name;
 
          IF xx_cdh_conv_master_pkg.get_hz_imp_g_miss_DATE(p_ext_attribs_row.d_ext_attr10) = FND_API.G_MISS_DATE
          THEN
            p_user_data_table(j).attr_value_DATE := NULL;
          ELSE
            p_user_data_table(j).attr_value_DATE := p_ext_attribs_row.d_ext_attr10;
          END IF;
        END IF;
      END IF;
    END LOOP;

    p_return_status := gc_success;
  EXCEPTION 
    WHEN OTHERS 
    THEN 
      IF p_error_msg IS NULL
      THEN 
        p_error_msg := 'Error while building the extension table ..'|| SQLERRM;
      END IF;
      p_return_status := gc_failure;
  END build_extension_table;


  -- +========================================================================================+
  -- | Name  : Insert_eBill_trans_dtls                                                        |
  -- | Description   : This Procedure inserts the records into ebill trans dtls table         |
  -- |                                                                                        |
  -- |                                                                                        |
  -- | Parameters    :                                                                        |
  -- +========================================================================================+

  PROCEDURE insert_ebill_trans_dtls(p_cust_doc_id         IN xx_cdh_ebl_transmission_dtl.cust_doc_id%TYPE,
                                    p_error_msg           OUT VARCHAR2)
  IS

  lc_email_subject             xx_cdh_ebl_transmission_dtl.email_subject%TYPE;
  lc_email_std_msg             xx_cdh_ebl_transmission_dtl.email_std_message%TYPE;
  lc_email_std_disclaim1       xx_cdh_ebl_transmission_dtl.email_std_disclaimer%TYPE;
  lc_email_std_disclaim2       xx_cdh_ebl_transmission_dtl.email_std_disclaimer%TYPE;
  lc_email_std_disclaime       xx_cdh_ebl_transmission_dtl.email_std_disclaimer%TYPE;
  lc_email_signature           xx_cdh_ebl_transmission_dtl.email_signature%TYPE;
  lc_email_logo_file_name      xx_cdh_ebl_transmission_dtl.email_logo_file_name%TYPE;

  BEGIN
    lc_email_subject            := NULL;
    lc_email_std_msg            := NULL;
    lc_email_std_disclaim1      := NULL;
    lc_email_std_disclaim2      := NULL;
    lc_email_std_disclaime      := NULL;
    lc_email_signature          := NULL;
    lc_email_logo_file_name     := NULL;


    log_msg('Getting Profile values ..');
    
    SELECT fnd_profile.value('XXOD_EBL_EMAIL_STD_SUB_STAND')
    INTO lc_email_subject 
    FROM DUAL;

    log_msg('Email Subject :'|| lc_email_subject);

    SELECT fnd_profile.value('XXOD_EBL_EMAIL_STD_MSG')
    INTO lc_email_std_msg
    FROM DUAL;
    
    log_msg('Email Std msg :'|| lc_email_std_msg);

    SELECT fnd_profile.value('XXOD_EBL_EMAIL_STD_DISCLAIM')
    INTO lc_email_std_disclaim1
    FROM DUAL;

    log_msg('Email std disclaim1 :'|| lc_email_std_disclaim1);
    
    SELECT fnd_profile.value('XXOD_EBL_EMAIL_STD_DISCLAIM1')
    INTO lc_email_std_disclaim2
    FROM DUAL;

    log_msg('Email std disclaim2 :'|| lc_email_std_disclaim2);

    
    lc_email_std_disclaime := lc_email_std_disclaim1||lc_email_std_disclaim2;

    log_msg('Email std disclaime :'|| lc_email_std_disclaime);
    
    select fnd_profile.value('XXOD_EBL_EMAIL_STD_SIGN')
    into lc_email_signature
    from dual;

    log_msg('Email Signature :'|| lc_email_signature);
    
    select fnd_profile.value('XXOD_EBL_LOGO_FILE')
    into lc_email_logo_file_name
    from dual;
    
    log_msg('Email logo file name :'|| lc_email_logo_file_name);

    log_msg('Calling XX_CDH_EBL_TRANS_DTL_PKG.insert_row pkg to insert row ..');

    XX_CDH_EBL_TRANS_DTL_PKG.insert_row(p_cust_doc_id             => p_cust_doc_id,
                                        p_email_subject           => lc_email_Subject,
                                        p_email_std_message       => lc_email_std_msg,
                                        p_email_custom_message    => NULL,
                                        p_email_std_disclaimer    => lc_email_std_disclaime,
                                        p_email_signature         => lc_email_signature,
                                        p_Email_logo_required     => NULL,
                                        p_email_logo_file_name    => lc_email_logo_file_name,
                                        p_ftp_direction           => NULL , 
                                        p_ftp_transfer_type       => NULL ,
                                        p_ftp_destination_site    => NULL ,
                                        p_ftp_destination_folder  => NULL ,
                                        p_ftp_user_name           => NULL ,
                                        p_ftp_password            => NULL ,
                                        p_ftp_pickup_server       => NULL ,
                                        p_ftp_pickup_folder       => NULL ,
                                        p_ftp_cust_contact_name   => NULL ,
                                        p_ftp_cust_contact_email  => NULL ,
                                        p_ftp_cust_contact_phone  => NULL ,
                                        p_ftp_notify_customer     => NULL ,
                                        p_ftp_cc_emails           => NULL ,
                                        p_ftp_email_sub           => NULL ,
                                        p_ftp_email_content       => NULL ,
                                        p_ftp_send_zero_byte_file => NULL ,
                                        p_ftp_zero_byte_file_text  => NULL ,
                                        p_ftp_zero_byte_notifi_txt => NULL ,
                                        p_cd_file_location         => NULL ,
                                        p_cd_send_to_address       => NULL ,
                                        p_comments                => NULL );

  EXCEPTION 
    WHEN OTHERS
    THEN 
      p_error_msg     := 'Error inserting rec into ebill trans dtls '|| SQLERRM ;
  END insert_ebill_trans_dtls;

  -- +========================================================================================+
  -- | Name  :Insert_ebill_file_name_dtls                                                         |
  -- | Description   : This Procedure inserts the records into ebill file name dtls table         |
  -- |                                                                                        |
  -- |                                                                                        |
  -- | Parameters    :                                                                        |
  -- +========================================================================================+

  PROCEDURE Insert_ebill_file_name_dtls (p_cust_doc_id         IN   xx_cdh_ebl_transmission_dtl.cust_doc_id%TYPE,
                                         p_document_type       IN   VARCHAR2,
                                         p_error_msg           OUT  VARCHAR2)
  IS

  ln_order_seq        NUMBER;
  ln_file_name_id     NUMBER;
  lc_field_value      xx_fin_translatevalues.source_value2%TYPE;
  lc_file_name_id     NUMBER;
  ln_file_id          NUMBER;
  lc_doc_field_value  VARCHAR2(100);

  e_process_exception  exception;

  BEGIN

    ln_order_seq     := 10;
    ln_file_name_id  := NULL;
    p_error_msg  := NULL;                            
    lc_field_value   := NULL;

    log_msg('P_document_type :'|| p_document_type);
      
    For i IN 1..4
    LOOP         
      BEGIN
      
        SELECT xx_cdh_ebl_file_name_id_s.nextval 
        INTO lc_file_name_id 
        FROM DUAL;

        lc_field_value := NULL;

        IF p_document_type = 'Consolidated Bill'
        THEN 
          lc_doc_field_value := 'Consolidated Bill Number';
        ELSE
          lc_doc_field_value := 'Invoice Number';
        END IF ;

        IF ln_order_seq = 10
        THEN
          lc_field_value := 'Account Number';
        ELSIF ln_order_seq = 20 
        THEN
          lc_field_value := 'Customer_DocID';
        ELSIF ln_order_seq = 30 
        THEN
          lc_field_value := 'Bill To Date';
        ELSIF ln_order_seq = 40 
        THEN
          lc_field_value := lc_doc_field_value;
        END IF;

        log_msg('lc_field_value :'|| lc_field_value);

        SELECT xftv.source_value1
        INTO ln_file_id
        FROM xx_fin_translatedefinition xft,
             xx_fin_translatevalues xftv
        WHERE xft.translate_id   = xftv.translate_id
        AND xft.enabled_flag     = 'Y'
        AND xftv.enabled_flag    = 'Y'
        AND translation_name     = 'XX_CDH_EBILLING_FIELDS'
        AND source_value2        = lc_field_value;

        log_msg('inserting into file dtl pkg..');
        log_msg('Cust doc id: '|| p_cust_doc_id);
        
        xx_cdh_ebl_file_name_dtl_pkg.insert_row(p_ebl_file_name_id     => lc_file_name_id ,
                                                p_cust_doc_id          => p_cust_doc_id,
                                                p_file_name_order_seq  => ln_order_seq,
                                                p_field_id             => ln_file_id,
                                                p_constant_value       => null,
                                                p_default_if_null      => null,
                                                p_comments             => null);
                               
       ln_order_seq := ln_order_seq + 10;                                                                              
      EXCEPTION
        WHEN OTHERS
        THEN 
          p_error_msg := 'Error inserting rec into Insert_ebill_file_name_dtls  '|| SQLERRM ;
          RAISE e_process_exception;
      END;
   END LOOP;
    
  EXCEPTION 
    WHEN OTHERS
    THEN 
      IF p_error_msg IS NULL
      THEN 
        p_error_msg := 'Error inserting rec into Insert_ebill_file_name_dtls  '|| SQLERRM ;
      END IF;
  END Insert_ebill_file_name_dtls ;

  -- +========================================================================================+
  -- | Name  :Insert_ebill_Main_dtls                                                          |
  -- | Description   : This Procedure inserts the records into Insert_ebill_Main_dtls table   |
  -- |                                                                                        |
  -- |                                                                                        |
  -- | Parameters    :                                                                        |
  -- +========================================================================================+

  PROCEDURE Insert_ebill_main_dtls(p_cust_doc_id         IN xx_cdh_ebl_transmission_dtl.cust_doc_id%TYPE,
                                   p_cust_account_id     IN hz_cust_accounts.cust_account_id%TYPE,
                                   p_error_msg           OUT VARCHAR2)
  IS

  ln_order_seq             NUMBER;
  ln_file_name_id          NUMBER;
  lc_associate             fnd_lookups.lookup_code%TYPE;
  lc_file_processing_code  fnd_lookups.lookup_code%TYPE;

  BEGIN
    log_msg('inserting into Ebil Main pkg..');

     -- get associate id 
    SELECT lookup_code
    INTO lc_associate
    FROM fnd_lookups
    WHERE lookup_type = 'XXOD_EBL_ASSOCIATE'  
    AND  meaning = 'OMX'
    AND enabled_flag = 'Y';

    log_msg('lc associate :'|| lc_associate);
  
    -- get file processing method id
  
    SELECT lookup_code
    INTO lc_file_processing_code
    FROM fnd_lookups
    WHERE lookup_type = 'XXOD_EBL_FILE_PROC_MTD'
    AND meaning = 'Multiple Orders per File. Single File per Transmission';

    log_msg('lc file Processing code :' || lc_file_processing_code);
          
          
    xx_cdh_ebl_main_pkg.insert_row(p_cust_doc_id               => p_cust_doc_id,
                                   p_cust_account_id           => p_cust_account_id , 
                                   p_ebill_transmission_type   => 'EMAIL',
                                   p_ebill_associate           => lc_associate, --160, 
                                   p_file_processing_method    => lc_file_processing_code, --'03',
                                   p_file_name_ext             => 'PDF',
                                   p_max_file_size             => 10,
                                   p_max_transmission_size     => 10,
                                   p_zip_required              => 'N',
                                   p_zipping_utility           => NULL,
                                   p_zip_file_name_ext         => NULL,
                                   p_od_field_contact          => NULL,
                                   p_od_field_contact_email    => NULL,
                                   p_od_field_contact_phone    => NULL,
                                   p_client_tech_contact       => NULL,
                                   p_client_tech_contact_email => NULL,
                                   p_client_tech_contact_phone => NULL,
                                   p_file_name_seq_reset       => NULL,
                                   p_file_next_seq_NUMBER      => NULL,
                                   p_file_seq_reset_DATE       => NULL,
                                   p_file_name_max_seq_NUMBER  => NULL
                                   );
  EXCEPTION 
    WHEN OTHERS
    THEN 
      IF p_error_msg IS NULL
      THEN 
        p_error_msg := 'Error inserting rec into Insert_ebill_main_dtls  '|| SQLERRM ;
      END IF;
  END Insert_ebill_Main_dtls;



  -- +========================================================================================+
  -- | Name  :Update_status                                                                   |
  -- | Description   : This Procedure updates the record status in the stg table              |
  -- |                                                                                        |
  -- |                                                                                        |
  -- | Parameters    :                                                                        |
  -- +========================================================================================+

  PROCEDURE Update_status(p_record_id           IN     NUMBER,
                          p_Status              IN     VARCHAR2,
                          p_payterm_name        IN     ra_terms.name%TYPE,
                          p_error_message       IN OUT VARCHAR2)
  IS

  BEGIN

    log_msg('updating status .....');

    UPDATE xx_cdh_omx_bill_docs_stg
    SET Status            = p_status,
        ods_payment_term  = p_payterm_name,
        error_message     = p_error_message
    WHERE record_id   = p_record_id;

    log_msg('Number of Rows updated :' || SQL%ROWCOUNT);

  EXCEPTION 
    WHEN OTHERS
    THEN 
      IF p_error_message IS NULL
      THEN 
        p_error_message := 'Error while updating the status  '|| SQLERRM ;
      END IF;
  END update_status;

  -- +========================================================================================+
  -- | Name  :Create_Document                                                                 |
  -- | Description   : This Procedure creates the billing document                            |
  -- |                                                                                        |
  -- |                                                                                        |
  -- | Parameters    :                                                                        |
  -- +========================================================================================+

  PROCEDURE Create_Document(p_cursor_rec          IN  xx_cdh_omx_bill_docs_stg%ROWTYPE,
                            p_payment_term_info   IN  ra_terms%ROWTYPE,
                            p_customer_info       IN  hz_cust_accounts%ROWTYPE,
                            p_doc_type            IN  VARCHAR2,
                            p_delivery_method     IN  VARCHAR2,
                            p_billing_type        IN  VARCHAR2,
                            p_mbs_doc_id          IN  VARCHAR2,
                            p_document_type       IN  vARCHAR2,
                            p_default_used        IN  VARCHAR2,
                            p_ebill_cnt_not_rec   IN  VARCHAR2,
                            p_return_Status       OUT VARCHAR2,
                            p_error_msg           OUT VARCHAR2)
  IS

  ln_order_seq       NUMBER;
  ln_file_name_id    NUMBER;
  lc_user_table      EGO_USER_ATTR_ROW_TABLE  := EGO_USER_ATTR_ROW_TABLE();
  lc_data_table      EGO_USER_ATTR_DATA_TABLE := EGO_USER_ATTR_DATA_TABLE();
  lr_od_ext_attr_rec xx_od_ext_attr_rec;
  ln_cust_doc_id     NUMBER;
  lc_billing_type    VARCHAR2(1);
  lc_summary_billing VARCHAR2(1);
  lc_status          VARCHAR2(50);
  lc_doc_type        VARCHAR2(10);
  l_return_status    VARCHAR2(1000);
  l_errorcode        NUMBER;
  l_msg_count        NUMBER;
  l_msg_data         VARCHAR2(1000);
  l_errors_tbl       ERROR_HANDLER.Error_Tbl_Type;
  l_failed_row_id_list   VARCHAR2(1000);
  ln_msg_text            VARCHAR2(32000);
  lc_start_date      DATE;


  e_process_exception  EXCEPTION;
  BEGIN

    lr_od_ext_attr_rec  := NULL;
    lc_doc_type         := NULL;
    lc_billing_type     := NULL;
    lc_summary_billing  := NULL;
    lc_status           := NULL;

    log_msg('Create document .....');

    log_msg('Get next cust doc id seq value ..');

    SELECT xx_Cdh_cust_doc_id_s.nextval
    INTo ln_cust_doc_id 
    FROM DUAL;

    log_msg('ln_cust_doc_id :'|| ln_cust_doc_id);

    SELECT DECODE(p_doc_type, '1','Y', 'N')
    INTO lc_doc_type
    FROM DUAL;

    SELECT DECODE(p_billing_type,'DI', 'Y', 'N')
    INTO lc_billing_type
    FROM DUAL;

    SELECT DECODE(p_cursor_rec.summary_bill_flag , 'Y', 'Y','N')
    INTO lc_summary_billing
    FROM DUAL;


    IF (p_default_used = 'Y' OR p_ebill_cnt_not_rec = 'Y')
    THEN 
      lc_status      := 'IN_PROCESS';
      lc_start_date  :=  NULL;
    ELSE 
      SELECT DECODE(p_delivery_method,'ePDF', 'IN_PROCESS','COMPLETE')
      INTO lc_status
      FROM DUAL;

      lc_start_date  := TRUNC(SYSDATE);
    END IF;

    log_msg('lc_doc_type        :' ||lc_doc_type);
    log_msg('lc_billing_type    :' ||lc_billing_type);
    log_msg('lc_summary_billing :' ||lc_summary_billing);
    log_msg('lc_doc_status      :' ||lc_status);
    log_msg('Payment term       :' ||p_payment_term_info.name); 
    log_msg('Payment term id    :' ||p_payment_term_info.term_id);
    log_msg('ebill cont received :'||p_ebill_cnt_not_rec);

          
    lr_od_ext_attr_rec.Attribute_group_code   := 'BILLDOCS'; 
    lr_od_ext_attr_rec.record_id              := p_cursor_rec.record_id;                        --101; 
    lr_od_ext_attr_rec.Interface_entity_name  := 'ACCOUNT' ;
    lr_od_ext_attr_rec.cust_acct_id           := p_customer_info.cust_account_id;               --21929541; 
    lr_od_ext_attr_rec.c_ext_attr1            := p_document_type ;                              --'Invoice'; -- Document_type -- consolidated or invoiced
    lr_od_ext_attr_rec.c_ext_attr2            := lc_doc_type ;                                  -- Paydoc or Infodoc
    lr_od_ext_attr_rec.c_ext_attr3            := p_delivery_method;                             -- 'ePDF';      -- Delivery Method 
    lr_od_ext_attr_rec.c_ext_attr4            := NULL;                                          -- special handling
    lr_od_ext_attr_rec.c_ext_attr5            := 'N' ;                                          --,Signature Required
    lr_od_ext_attr_rec.c_ext_attr6            := NULL;                                          --'WEEKLY';      -- Cycle  ?? HOW TO DERIVE THIS
    lr_od_ext_attr_rec.c_ext_attr7            := lc_billing_type;                               -- Direct_document -- Direct or Indirect
    lr_od_ext_attr_rec.c_ext_attr8            := NULL; 
    lr_od_ext_attr_rec.c_ext_attr9            := NULL;
    lr_od_ext_attr_rec.c_ext_attr10           := NULL;
    lr_od_ext_attr_rec.c_ext_attr11           := lc_summary_billing;                             -- Populate if consolidated is Y else N
    lr_od_ext_attr_rec.c_ext_attr12           := NULL;
    lr_od_ext_attr_rec.c_ext_attr13           := NULL;
    lr_od_ext_attr_rec.c_ext_attr14           := p_payment_term_info.name;                      --'WKON060000N030'; -- Payment term
    lr_od_ext_attr_rec.c_ext_attr15           := NULL;
    lr_od_ext_attr_rec.c_ext_attr16           := lc_status;                                       --- Status 'COMPLETE'
    lr_od_ext_attr_rec.c_ext_attr17           := NULL;
    lr_od_ext_attr_rec.c_ext_attr18           := NULL;
    lr_od_ext_attr_rec.c_ext_attr19           := NULL;
    lr_od_ext_attr_rec.c_ext_attr20           := NULL;
    lr_od_ext_attr_rec.N_Ext_attr1            := p_mbs_doc_id;                                    --10000;         -- MBS DOC ID 
    lr_od_ext_attr_rec.N_Ext_attr2            := ln_cust_doc_id;                                  -- CUST DOC ID 
    lr_od_ext_attr_rec.N_Ext_attr3            := 1 ;                                              --NO OF COPIES --1
    lr_od_ext_attr_rec.N_Ext_attr4            := NULL;
    lr_od_ext_attr_rec.N_Ext_attr5            := NULL;
    lr_od_ext_attr_rec.N_Ext_attr6            := NULL;
    lr_od_ext_attr_rec.N_Ext_attr7            := NULL;
    lr_od_ext_attr_rec.N_Ext_attr8            := NULL;
    lr_od_ext_attr_rec.N_Ext_attr9            := NULL;
    lr_od_ext_attr_rec.N_Ext_attr10           := NULL;
    lr_od_ext_attr_rec.N_Ext_attr11           := NULL;
    lr_od_ext_attr_rec.N_Ext_attr12           := NULL;
    lr_od_ext_attr_rec.N_Ext_attr13           := NULL;
    lr_od_ext_attr_rec.N_Ext_attr14           := NULL;
    lr_od_ext_attr_rec.N_Ext_attr15           := NULL;
    lr_od_ext_attr_rec.N_Ext_attr16           := 0; --NULL;
    lr_od_ext_attr_rec.N_Ext_attr17           := 0; --NULL;
    lr_od_ext_attr_rec.N_Ext_attr18           := p_payment_term_info.term_id;                                --1330; -- Payment term id
    lr_od_ext_attr_rec.N_Ext_attr19           := p_doc_type ;                                                --1;     -- 0 --infodoc and 1 --paydoc
    lr_od_ext_attr_rec.N_Ext_attr20           := p_cursor_rec.batch_id;                                      -- batch id
    lr_od_ext_attr_rec.D_Ext_attr1            := lc_start_date;                                             -- start date
    lr_od_ext_attr_rec.d_Ext_attr2            := NULL;                                                       -- End date 
    lr_od_ext_attr_rec.d_Ext_attr3            := NULL;
    lr_od_ext_attr_rec.d_Ext_attr4            := NULL;
    lr_od_ext_attr_rec.d_Ext_attr5            := NULL;
    lr_od_ext_attr_rec.d_Ext_attr6            := NULL;
    lr_od_ext_attr_rec.d_Ext_attr7            := NULL;
    lr_od_ext_attr_rec.d_Ext_attr8            := NULL;
    lr_od_ext_attr_rec.d_Ext_attr9            := SYSDATE;                                                   -- request start date
    lr_od_ext_attr_rec.d_Ext_attr10           := NULL;


    log_msg( ' Calling Bulid Extension table ...');

    Build_extension_table
         (p_user_row_table        => lc_user_table,
          p_user_data_table       => lc_data_table,
          p_ext_attribs_row       => lr_od_ext_attr_rec,
          p_return_Status         => p_return_status,
          p_error_msg             => p_error_msg);
                    
    IF lc_user_table.count >0 
    THEN
      log_msg('User Table count..'|| lc_user_table.count); 
    END IF;

    IF lc_data_table.count >0 
    THEN
      log_msg('Data Table count..'|| lc_data_table.count); 
    END IF;                     
                     
    log_msg('calling process acct..');
         
    XX_CDH_HZ_EXTENSIBILITY_PUB.Process_Account_Record(p_api_version           => XX_CDH_CUST_EXTEN_ATTRI_PKG.G_API_VERSION,
                                                       p_cust_account_id       => p_customer_info.cust_account_id,
                                                       p_attributes_row_table  => lc_user_table,
                                                       p_attributes_data_table => lc_data_table,
                                                       p_log_errors            => FND_API.G_FALSE,
                                                       x_failed_row_id_list    => l_failed_row_id_list,
                                                       x_return_status         => l_return_status,
                                                       x_errorcode             => l_errorcode,
                                                       x_msg_count             => l_msg_count,
                                                       x_msg_data              => l_msg_data);

    log_msg('Process_Account_Record : l_return_status '|| l_return_status);
    
    IF l_return_status != FND_API.G_RET_STS_SUCCESS
    THEN
      IF l_msg_count > 0
      THEN
        ERROR_HANDLER.Get_Message_List(l_errors_tbl);
        FOR i IN 1..l_errors_tbl.COUNT
        LOOP
          ln_msg_text := ln_msg_text||' '||l_errors_tbl(i).message_text;
        END LOOP;
      ELSE 
        ln_msg_text := l_msg_data;
      END IF;

      p_error_msg := ln_msg_text;

      log_msg('XX_HZ_EXTENSIBILITY_PUB.Process_Account_Record API returned Error.');
      RAISE e_process_exception;
    END IF;

     --  lx_od_ext_attrib_stg(i).interface_status := 7;
    log_msg( 'XX_HZ_EXTENSIBILITY_PUB.Process_Account_Record API successful.');

    IF p_delivery_method = 'ePDF'
    THEN
      log_msg('Calling insert ebill Trans DTLS ..');

      Insert_ebill_trans_dtls(p_cust_doc_id  => ln_cust_doc_id,
                              p_error_msg    => p_error_msg);

      IF p_error_msg IS NOT NULL
      THEN 
        RAISE e_process_exception;
      END IF;
 
      log_msg('Calling insert ebill file name dtls ..');

      Insert_ebill_file_name_dtls (p_cust_doc_id     => ln_cust_doc_id,
                                   p_document_type   => p_document_type,
                                   p_error_msg       => p_error_msg);

      IF p_error_msg IS NOT NULL
      THEN 
        RAISE e_process_exception;
      END IF;

      log_msg('Calling insert ebill main dtls ..');

      Insert_ebill_main_dtls(p_cust_doc_id         => ln_cust_doc_id,
                             p_cust_account_id     => p_customer_info.cust_account_id,
                             p_error_msg           => p_error_msg);

      IF p_error_msg IS NOT NULL
      THEN 
        RAISE e_process_exception;
      END IF;
    END IF;

    p_return_status := gc_Success;

  EXCEPTION 
    WHEN OTHERS
    THEN 
      IF p_error_msg IS NULL
      THEN 
        p_error_msg := 'Error inserting rec into Insert_ebill_main_dtls  '|| SQLERRM ; 
      END IF;
      log_msg('error'||p_error_msg);
--      fnd_file.put_line(fnd_file.log, p_error_msg);
      p_return_status := gc_failure;
  END create_document;

  -- +===================================================================+
  -- | Name  : extract                                                   |
  -- | Description     : The extract is the main                         |
  -- |                   procedure that will extract the records         |
  -- |                   from staging table to create the documents      |
  -- |                                                                   |
  -- | Parameters      : x_retcode           OUT                         |
  -- |                   x_errbuf            OUT                         |
  -- |                   p_debug_flag        IN -> Debug Flag            |
  -- |                   p_status            IN -> Record status         |
  -- +===================================================================+

  PROCEDURE extract( x_retcode           OUT NOCOPY     NUMBER
                    ,x_errbuf            OUT NOCOPY     VARCHAR2
                    ,p_aops_acct_number  IN             xx_cdh_omx_bill_docs_stg.aops_customer_number%TYPE
                    ,p_status            IN             xx_cdh_omx_bill_docs_stg.status%TYPE
                    ,p_debug_flag        IN             VARCHAR2
                    ,p_batch_id          IN             xx_cdh_omx_bill_docs_stg.batch_id%TYPE
                    )
  IS

  lc_cust_acct_info            hz_cust_accounts_all%ROWTYPE;
  lc_billing_type              xx_cdh_mod4_Sfdc_cust_stg.billing_type%TYPE;
  lc_translation_info          xx_fin_translatevalues%ROWTYPE;
  lc_payment_term_info         ra_terms%ROWTYPE;
  lc_default_delivery_used     VARCHAR2(1);
  lc_default_payterm_used      VARCHAR2(1); 
  lc_default_trans_used        VARCHAR2(1);
  lc_default_used              VARCHAR2(1);
  lc_billing_flag              VARCHAR2(10);
  lc_delivery_method           VARCHAR2(100);
  lc_mbs_doc_id                xx_fin_translatevalues.target_value1%TYPE;
  lc_document_type             xx_fin_translatevalues.target_value2%TYPE;
  lc_return_status             VARCHAR2(100);
  lc_error_message             VARCHAR2(4000);
  ln_dup_counts                NUMBER;
  ln_rows_updated              NUMBER;
  lc_infodoc_failure           VARCHAR2(1);
  ln_ebill_count               NUMBER := 0;
  lc_ebill_cont_not_received   VARCHAR2(1) := 'N';


  e_process_exception  EXCEPTION;


  CURSOR cur_docs ( p_status              IN xx_cdh_omx_bill_docs_stg.status%TYPE,
                    p_aops_acct_number    IN xx_cdh_omx_bill_docs_stg.aops_customer_number%TYPE,
                    p_batch_id            IN xx_cdh_omx_bill_docs_stg.batch_id%TYPE )
  IS 
  SELECT *
  FROM xx_cdh_omx_bill_docs_stg
  WHERE Status             = NVL(p_status , 'N')
  AND aops_customer_number = NVL(p_aops_acct_NUMBER, aops_customer_number)
  AND batch_id             = NVL(p_batch_id ,batch_id)
  ORDER BY batch_id;

  CURSOR cur_info(p_record_id IN  xx_fin_translatevalues.source_value1%TYPE)
  IS 
  SELECT xftv.*
  FROM xx_fin_translatedefinition xft,
       xx_fin_translatevalues xftv
  WHERE xft.translate_id   = xftv.translate_id
  AND xft.enabled_flag     = 'Y'
  AND xftv.enabled_flag    = 'Y'
  AND translation_name     = 'XXOD_MOD4_OMX_INFODOC_DET'
  AND source_value1        = p_record_id;


  BEGIN

    fnd_file.put_line(fnd_file.log , 'Input parameters .....:');
    fnd_file.put_line(fnd_file.log , 'p_debug_flag: '||p_debug_flag);
    fnd_file.put_line(fnd_file.log , 'p_status: '|| p_status);
    fnd_file.put_line(fnd_file.log , 'p_batch_id: '|| p_batch_id);
    fnd_file.put_line(fnd_file.log , 'p_aops_acct_number: '|| p_aops_acct_number);

    IF(p_debug_flag = 'Y')
    THEN
       g_debug_flag := TRUE;
    ELSE
       g_debug_flag := FALSE;
    END IF;

    lc_cust_acct_info    := NULL;
    lc_billing_type      := NULL;
    lc_translation_info  := NULL;
    lc_payment_term_info := NULL;
    lc_billing_flag      := NULL;
    lc_delivery_method   := NULL;
    lc_mbs_doc_id        := NULL;
    lc_document_type     := NULL;
    lc_return_status     := NULL;
    lc_error_message     := NULL;
    ln_dup_counts        := NULL;

    log_msg('Check Duplicate data exists .... ');
    
    BEGIN 

      SELECT COUNT(1)
      INTO ln_dup_counts
      FROM xx_cdh_omx_bill_docs_stg a
      WHERE EXISTS ( SELECT 1 
                     FROM xx_cdh_omx_bill_docs_stg b
                     WHERE aops_customer_NUMBER = A.aops_customer_NUMBER
                     AND status = NVL(p_status, status)
                     AND ROWID < A.ROWID );

      log_msg( ln_dup_counts || ' Duplicate Records Exists ...');

      IF ln_dup_counts > 0 
      THEN 
        log_msg( 'Updating all the Dup records to Error');

        UPDATE xx_cdh_omx_bill_docs_stg a
        SET status        = 'E',
            error_message = 'Duplicate Document ....'
        WHERE EXISTS ( SELECT 1 
                       FROM xx_cdh_omx_bill_docs_stg b
                       WHERE aops_customer_number = A.aops_customer_number
                       AND status = NVL(p_status, status)
                       AND ROWID < A.ROWID );

        ln_rows_upDATEd := SQL%ROWCOUNT;

        log_msg( ln_rows_updated ||' Rows updated ');

        COMMIT;
      END IF;
    EXCEPTION 
      WHEN OTHERS
      THEN 
        log_msg('Error While updating the duplicate records ..'||SQLERRM);
        ROLLBACK;       
    END;
    
    BEGIN 
      log_msg('Update SORT fields .... ');
  
      UPDATE xx_cdh_omx_bill_docs_stg a
        SET sort_by_consignee_exp_rpt    = 'N',
            sort_by_costcenter_exp_rpt   = 'N',
            sort_by_po_exp_rpt           = 'N'
      WHERE print_exp_rep_flag = 'N'
      AND   status = 'N';
 
      ln_rows_upDATEd := SQL%ROWCOUNT;

      log_msg( ln_rows_updated ||' Rows updated ');

      COMMIT;
    EXCEPTION 
      WHEN OTHERS
      THEN 
        log_msg('Error While updating the sort field records ..'||SQLERRM);
        ROLLBACK;       
    END;

    BEGIN 
      log_msg('Update all the print fileds when summary bill flag is N ');
  
      UPDATE xx_cdh_omx_bill_docs_stg a
      SET print_exp_rep_flag           = 'N', 
          print_inv_detail_flag        = 'N',
          print_remittance_page        = 'N',
          sort_by_consignee_exp_rpt    = 'N',
          sort_by_costcenter_exp_rpt   = 'N',
          sort_by_po_exp_rpt           = 'N'
      WHERE summary_bill_flag = 'N'
      AND   status = 'N';
 
      ln_rows_upDATEd := SQL%ROWCOUNT;
      log_msg( ln_rows_updated ||' Rows updated ');

      COMMIT;
    EXCEPTION 
      WHEN OTHERS
      THEN 
        log_msg('Error While updating the sort field records ..'||SQLERRM);
        ROLLBACK;       
    END;
    
    FOR cur_doc_rec IN cur_docs(p_status              => p_status,
                                p_aops_acct_number    => p_aops_acct_number,
                                p_batch_id            => p_batch_id)
    LOOP
      BEGIN

        lc_default_payterm_used     := NULL;
        lc_cust_acct_info           := NULL;
        lc_return_status            := NULL;
        lc_error_message            := NULL;
        lc_billing_type             := NULL;
        lc_translation_info         := NULL;
        lc_payment_term_info        := NULL;
        lc_default_delivery_used    := NULL;
        lc_default_trans_used       := NULL;
        lc_mbs_doc_id               := NULL;
        lc_default_used             := 'N'; 
        ln_ebill_count              := 0;
        lc_ebill_cont_not_received  := 'N';

        lc_return_status := get_customer_details(p_aops_cust_number   => cur_doc_rec.aops_customer_number,
                                                 p_customer_info      => lc_cust_acct_info,
                                                 p_error_msg          => lc_error_message);

        IF (lc_return_status != gc_success)
        THEN
          RAISE e_process_exception;
        END IF;

        log_msg(' Processing document for AOPS customer NUMBER ..'|| cur_doc_rec.aops_customer_NUMBER);

        log_msg(' Check if the active document exists ..if so , end DATE them ..');

        lc_return_status := end_date_existing_doc(p_aops_customer_NUMBER => cur_doc_rec.aops_customer_number,
                                                  p_cust_acct_id         => lc_cust_acct_info.cust_account_id,
                                                  p_end_date             => TRUNC(SYSDATE)-1,
                                                  p_error_msg            => lc_error_message);

        IF lc_return_status != gc_success
        THEN 
          RAISE e_process_exception;
        END IF;

        lc_return_status := derive_billing_type(p_cursor_rec      => cur_doc_rec,
                                                p_billing_type    => lc_billing_type,
                                                p_error_msg       => lc_error_message);

        IF lc_return_status != gc_success
        THEN 
          RAISE e_process_exception;
        END IF;


        IF lc_billing_type IN ( 'DI', 'IS')
        THEN 
           
          log_msg('Getting Translastion info ..');

          lc_return_status := get_translation_info( p_cursor_rec       => cur_doc_rec,
                                                    p_translation_info => lc_translation_info,
                                                    p_default_used     => lc_default_trans_used,
                                                    p_error_msg        => lc_error_message);

          IF lc_return_status != gc_success
          THEN 
            RAISE e_process_exception;
          END IF;

          log_msg('calling the payment term info ..');

          lc_return_status := get_payment_term_info(p_cursor_rec        => cur_doc_rec,
                                                    p_doc_type          => lc_translation_info.target_value2,
                                                    p_payment_term_info => lc_payment_term_info,
                                                    p_default_used      => lc_default_payterm_used,
                                                    p_error_msg         => lc_error_message);

          IF lc_return_status != gc_success
          THEN 
            RAISE e_process_exception;
          END IF;

          IF lc_translation_info.target_value2 = 'Invoice' --cur_doc_rec.summary_bill_flag = 'N'
          THEN  
            lc_billing_flag := cur_doc_rec.print_daily_flag;
             
             -- Check Print daily flag . if its N OR NULL.. raise an error
            
            IF ( cur_doc_rec.print_daily_flag IS NULL OR 
                 cur_doc_rec.print_daily_flag = 'N')
            THEN 
              lc_error_message := 'Print Daily is : '|| cur_doc_rec.print_daily_flag ||' and Summary Bill flag iS also N .';
              RAISE e_process_exception ;
            END IF;

          ELSIF lc_translation_info.target_value2 = 'Consolidated Bill' --cur_doc_rec.summary_bill_flag != 'N'
          THEN 
            lc_billing_flag := cur_doc_rec.summary_bill_flag;
          END IF;

          log_msg('Getting delivery method for lc_billing_flag..'|| lc_billing_flag);

          lc_return_status := derive_delivery_method(p_billing_flag      => lc_billing_flag,
                                                     p_delivery_method   => lc_delivery_method,
                                                     p_default_used      => lc_default_delivery_used,
                                                     p_error_msg         => lc_error_message);

          IF lc_return_status != gc_success
          THEN 
            RAISE e_process_exception;
          END IF;
    
          log_msg('Calling create document to create the paydoc  ..');

          lc_mbs_doc_id     := lc_translation_info.target_value1;
          lc_document_type  := lc_translation_info.target_value2; 

          log_msg('lc_mbs_doc_id :'|| lc_mbs_doc_id);
          log_msg('lc_document_type :'|| lc_document_type);

          IF ( lc_default_trans_used = 'Y' OR lc_default_payterm_used = 'Y' OR lc_default_delivery_used = 'Y' )
          THEN 
            lc_default_used := 'Y';
          END IF;


          -- Check ebill contact received 
          IF lc_delivery_method = 'ePDF'
          THEN 
            SELECT COUNT(1)
            INTO   ln_ebill_count
            FROM xx_cdh_omx_ebill_contacts_stg
            WHERE     1 = 1
            AND aops_customer_number = cur_doc_rec.aops_customer_number;

            IF ln_ebill_count = 0
            THEN 
              lc_ebill_cont_not_received := 'Y';
            END IF;
         
          END IF;
 
          log_msg(' ln_ebill_count :'|| ln_ebill_count);
          log_msg(' lc_ebill_cont_not_received :'|| lc_ebill_cont_not_received);

          IF (lc_ebill_cont_not_received = 'Y' OR lc_default_used = 'Y' )
          THEN 
            log_msg(' Reset the end date for the existing docs since the default value being used for current doc ..');

            lc_return_status := end_date_existing_doc(p_aops_customer_NUMBER => cur_doc_rec.aops_customer_number,
                                                      p_cust_acct_id         => lc_cust_acct_info.cust_account_id,
                                                      p_end_date             => NULL,
                                                      p_error_msg            => lc_error_message);

            IF lc_return_status != gc_success
            THEN 
              RAISE e_process_exception;
            END IF;

          END IF;
         
          Create_document( p_cursor_rec          => cur_doc_rec,
                           p_payment_term_info   => lc_payment_term_info,
                           p_customer_info       => lc_cust_acct_info,
                           p_doc_type            => 1, -- paydoc 
                           p_delivery_method     => lc_delivery_method, 
                           p_billing_type        => lc_billing_type,
                           p_mbs_doc_id          => lc_mbs_doc_id,
                           p_document_type       => lc_document_type,
                           p_default_used        => lc_default_used,
                           p_ebill_cnt_not_rec   => lc_ebill_cont_not_received,
                           p_return_status       => lc_return_status,
                           p_error_msg           => lc_error_message);

          IF lc_return_status != gc_success
          THEN 
            RAISE e_process_exception;
          END IF;

          --- check the default value flag --and set the error status 

          IF lc_return_status =  gc_success
          THEN
            log_msg( 'Check infodocs are needed ..');

            lc_infodoc_failure := NULL;

            FOR cur_info_rec IN cur_info ( p_record_id => lc_translation_info.source_value1)
            LOOP
              BEGIN
                lc_payment_term_info := NULL;
                lc_delivery_method   := NULL;
                lc_billing_flag      := NULL;

                log_msg('Calling create document to create the infodoc ....Record id :' || cur_info_rec.source_value1 );
                lc_mbs_doc_id     := cur_info_rec.target_value1;
                lc_document_type  := cur_info_rec.target_value2; 

                log_msg('Infodoc MBS DOC id :'|| lc_mbs_doc_id);
                log_msg('Infodoc Document type :'|| lc_document_type);

                log_msg('calling the payment term info for Infodoc..');

                lc_return_status := get_payment_term_info(p_cursor_rec        => cur_doc_rec,
                                                          p_doc_type          => cur_info_rec.target_value2,
                                                          p_payment_term_info => lc_payment_term_info,
                                                          p_default_used      => lc_default_payterm_used,
                                                          p_error_msg         => lc_error_message);

                IF lc_return_status != gc_success
                THEN 
                  RAISE e_process_exception;
                END IF;

                log_msg('deriving the delivery method for Infodoc..');

                IF cur_info_rec.target_value2 = 'Invoice' --cur_doc_rec.summary_bill_flag = 'N'
                THEN  
                  lc_billing_flag := cur_doc_rec.print_daily_flag;
             
                ELSE
                 lc_billing_flag := cur_doc_rec.summary_bill_flag;
                END IF;

                log_msg('Getting delivery method for infodoc for lc_billing_flag..'|| lc_billing_flag);

                lc_return_status := derive_delivery_method(p_billing_flag      => lc_billing_flag,
                                                           p_delivery_method   => lc_delivery_method,
                                                           p_default_used      => lc_default_delivery_used,
                                                           p_error_msg         => lc_error_message);

                IF lc_return_status != gc_success
                THEN 
                  RAISE e_process_exception;
                END IF;
                
                Create_document( p_cursor_rec          => cur_doc_rec,
                                 p_payment_term_info   => lc_payment_term_info,
                                 p_customer_info       => lc_cust_acct_info,
                                 p_doc_type            => 0, --infodoc 
                                 p_delivery_method     => lc_delivery_method,
                                 p_billing_type        => lc_billing_type,
                                 p_mbs_doc_id          => lc_mbs_doc_id,
                                 p_document_type       => lc_document_type,
                                 p_default_used        => lc_default_used,
                                 p_ebill_cnt_not_rec   => lc_ebill_cont_not_received,
                                 p_return_status       => lc_return_status,
                                 p_error_msg           => lc_error_message);

               IF lc_return_status != gc_success
               THEN 
                 -- RAISE e_process_exception;
                 lc_infodoc_failure := 'Y';
               END IF;
             EXCEPTION 
               WHEN OTHERS 
               THEN 
                 IF lc_error_message IS NULL
                 THEN 
                   lc_error_message := 'Error while creating info doc'|| lc_error_message || SQLERRM;
                 END IF;
                 RAISE e_process_exception;
             END;
           END LOOP; -- info loop
         ELSE 
           RAISE e_process_exception ;
         END IF; -- lc_return_status 

       ELSE
         lc_error_message := 'Billing Document has not been processed because Billing type is ' || lc_billing_type ;
         RAISE e_process_exception;
       END IF; -- document type

       IF ( lc_default_trans_used = 'Y' OR lc_default_payterm_used = 'Y' OR lc_default_delivery_used = 'Y' )
       THEN 
         lc_error_message := lc_error_message ||' '||'Either Default Payterm or MBS DOC or Delivery method used to create the doc .';
       END IF;

       IF lc_infodoc_failure = 'Y'
       THEN 
         lc_error_message := lc_error_message ||' Infodoc is in PROCESS' ;
         log_msg(lc_error_message);
       END IF;

       log_msg('Calling update status..');
    
       Update_status(p_record_id     => cur_doc_rec.record_id,
                     p_status        => 'C',
                     p_payterm_name  => lc_payment_term_info.name,
                     p_error_message => lc_error_message);

       log_msg('Commit the changes ..');
       COMMIT;
     EXCEPTION 
       WHEN OTHERS
       THEN 
         log_msg('Rollback the changes ..');
         ROLLBACK;
         fnd_file.put_line(fnd_file.log, lc_error_message);
         Update_status(p_record_id     => cur_doc_rec.record_id,
                       p_payterm_name  => lc_payment_term_info.name,
                       p_status        => 'E',
                       p_error_message => lc_error_message);
         log_msg('Commit the error log changes ..');
         log_exception ( p_error_location    =>  'XX_CDH_OMX_BILL_DOCUMENTS_PKG.EXTRACT'
                        ,p_error_msg         =>  lc_error_message
                        ,p_program_id        =>  cur_doc_rec.record_id);
         COMMIT;
     END;
   END LOOP; -- cur doc  
 EXCEPTION
   WHEN OTHERS
   THEN
     IF lc_error_message IS NULL
     THEN
       lc_error_message := 'Unable to process '||SQLERRM;
     END IF;
     fnd_file.put_line(fnd_file.log,lc_error_message);
     log_exception ( p_error_location    =>  'XX_CDH_OMX_BILL_DOCUMENTS_PKG.EXTRACT'
                    ,p_error_msg         =>  lc_error_message);
    x_retcode := 2;
    ROLLBACK;
 END extract;

END XX_CDH_OMX_BILL_DOCUMENTS_PKG;
/

Sho err