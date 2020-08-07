CREATE OR REPLACE PACKAGE BODY APPS.XX_AR_CONS_BILL_PKG AS
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |  Providge Consulting                                                                       |
-- +============================================================================================+
-- |  Name:  XX_AR_CONS_BILL_PKG                                                                |
-- |  Description:  This package is used to process the Consolidated Bill Reprints and Special  |
-- |                Handling.                                                                   |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         22-Jul-2007  B.Looman         Initial version                                  |
-- | 1.1         21-Aug-2007  B.Looman         Updated special handling data templates to have  |
-- |                                           the "_SPEC" suffix also                          |
-- | 1.2         28-Aug-2007  B.Looman         Add the EXTENSION_ID for special handling        |
-- | 1.3         05-Nov-2007  B.Looman         Index Out of Bounds error (no data found)        |
-- |                                           Defect 2548                                      |
-- | 1.3         07-Jun-2008  B.Seshadri       Add request id                                   |
-- | 1.4         01-Jul-2008  B.Seshadri       Comment lines 322, 323, 324 and 326 as we are    |
-- | 1.3         01-Ju1-2008  B.Seshadri       using only three templates DETAIL, SUMMARIZE     |
-- |                                           and ONE to run Reprints as well as Spl Handling. |
-- | 1.4         14-SEP-2008  B.Seshadri       Printer and number of copies are derived based   |
-- |                                           on the type of job [REPRINT OR Original Spl Handling] submitted. |
--.| 1.5         02-DEC-2008  Sambasiva Reddy  Changed for the Defect # 12223                   |
-- | 1.6         08-JAN-2009  Ranjith Prabu     Changes for defect 11993                        |
-- | 1.7         03-APR-2009  Gokila Tamilselvam Changed the view to base table                 |
-- | 1.8         15-APR-2009  Sambasiva Reddy D  Added Debug parameter                          |
-- | 1.9         29-MAY-2009  Gokila Tamilselvam Defect# 15063.                                 |
-- |                                             The logic of the attribute1 column is handled  |
-- |                                             in the procedure XX_AR_PRINT_NEW_CON_PKG.MAIN  |
-- | 2.0         14-JUL-2009  Samabsiva Reddy D  Defect# 631 (CR# 662) -- Applied Credit Memos  |
---| 2.1         02-SEP-2009  Gokila Tamilselvam Modified for Defect# 1451 CR 626 R1.1 Defect.  |
---| 2.2         18-NOV-2009  Bhuvaneswary S     Modified for R1.2 Defect# 3300 CR 619          |
-- | 2.3         15-DEC-2009  Gokila Tamilselvam Modified reprint_bill_document Procedure for   |
-- |                                             R1.2 Defect# 1210 CR# 466.                     |
-- | 2.4         04-MAR-2010  Tamil Vendhan L    Modified for R1.3 CR 738 Defect 2766           |
-- | 2.5         08-APR-2010  Lincy K            Modified for R1.3 defect 4761 updating WHO     |
-- |                                             columns                                        |
-- | 2.6         19-OCT-2015  Vasu Raparla       Removed schema References for R12.2            |
-- +============================================================================================+


GC_SPEC_HANDLING_SUFFIX         CONSTANT VARCHAR2(20)       := '_SPEC';


-- ============================================================================================
-- procedure to print the buffer to the concurrent program output file (or DBMS_OUTPUT)
-- ============================================================================================
PROCEDURE put_out_line
( p_buffer     IN      VARCHAR2      DEFAULT ' ' )
IS
BEGIN
  -- if in concurrent program, print to output file
  IF (FND_GLOBAL.CONC_REQUEST_ID > 0) THEN
    FND_FILE.put_line(FND_FILE.OUTPUT,NVL(p_buffer,' '));
  -- else print to DBMS_OUTPUT
  ELSE
    DBMS_OUTPUT.put_line(SUBSTR(NVL(p_buffer,' '),1,255));
  END IF;
END;


-- ============================================================================================
-- procedure to print the buffer to the concurrent program log file (or DBMS_OUTPUT)
-- ============================================================================================
PROCEDURE put_log_line
( p_buffer     IN      VARCHAR2      DEFAULT ' ' )
IS
BEGIN
  -- if in concurrent program, print to log file
  IF (FND_GLOBAL.CONC_REQUEST_ID > 0) THEN
    FND_FILE.put_line(FND_FILE.LOG,NVL(p_buffer,' '));
  -- else print to DBMS_OUTPUT
  ELSE
    DBMS_OUTPUT.put_line(SUBSTR(NVL(p_buffer,' '),1,255));
  END IF;
END;


-- ============================================================================================
-- function to get the default value for a given named parameter - assumed to be "Constant"
-- ============================================================================================
FUNCTION get_param_default_value
( p_conc_program_name       IN    VARCHAR2,
  p_parameter_name          IN    VARCHAR2 )
RETURN VARCHAR2
IS
  lc_sub_name        CONSTANT VARCHAR2(50)    := 'GET_PARAM_DEFAULT_VALUE';

  lc_default_type             VARCHAR2(1)     DEFAULT NULL;
  lc_default_value            VARCHAR2(2000)  DEFAULT NULL;

  lc_detail_level             VARCHAR2(30)    DEFAULT NULL;

  CURSOR c_param IS
    SELECT fdfc.default_type,
           fdfc.default_value
      FROM fnd_application fa,
           fnd_descr_flex_column_usages fdfc
     WHERE fa.application_id = fdfc.application_id
       AND fa.application_short_name = GC_APPL_SHORT_NAME
       AND fdfc.descriptive_flexfield_name = '$SRS$.' || p_conc_program_name
       AND srw_param = p_parameter_name;
BEGIN
  -- ============================================================================================
  -- Fetch the default type and value for this parameter
  -- ============================================================================================
  OPEN c_param;
  FETCH c_param
   INTO lc_default_type,
        lc_default_value;
  CLOSE c_param;

  IF (lc_default_type = 'C') THEN
    RETURN lc_default_value;   -- return constant default value
  ELSIF (lc_default_type IS NULL) THEN
    RETURN NULL;               -- return NULL if no default defined
  ELSE
    RAISE_APPLICATION_ERROR
    ( -20001, 'Trying to retrieve the concurrent program parameter default ' ||
      'value that is not a "Constant" type.' );
  END IF;
END;


-- ============================================================================================
-- function to get the conc program short name based on the mbs document id
--   conc program given is based on the document detail level (i.e. SUM, DTL, ONE, HDR)
-- ============================================================================================
FUNCTION get_conc_program_name
( p_mbs_document_id         IN    NUMBER,
  p_special_handling        IN    BOOLEAN    DEFAULT FALSE )
RETURN VARCHAR2
IS
  lc_sub_name        CONSTANT VARCHAR2(50)    := 'GET_CONC_PROGRAM_NAME';

  lc_detail_level             VARCHAR2(30)    DEFAULT NULL;

  lc_spec_handling_suffix     VARCHAR2(30)    DEFAULT NULL;

  CURSOR c_doc IS
    SELECT TRIM(doc_detail_level) doc_detail_level
      FROM xx_cdh_mbs_document_master
     WHERE document_id = p_mbs_document_id;
BEGIN
  -- ============================================================================================
  -- Fetch the detail level of the mbs document
  -- ============================================================================================
  OPEN c_doc;
  FETCH c_doc
   INTO lc_detail_level;
  CLOSE c_doc;
  
-- ==========================================================================   
-- We will use one template for both SPECIAL HANDLING and REPRINTS...
-- ==========================================================================   
  IF (lc_detail_level = 'SUMMARIZE') THEN
    RETURN 'XXARCBISUM';
  ELSIF (lc_detail_level = 'DETAIL') THEN
    RETURN 'XXARCBIDTL';
  ELSIF (lc_detail_level = 'HEADER') THEN
    RETURN 'XXARCBIHDR';
  ELSIF (lc_detail_level = 'ONE') THEN
    RETURN 'XXARCBIONE';
  ELSE
    RAISE_APPLICATION_ERROR
    ( -20001, 'The detail level "' || lc_detail_level ||
      '" for this document does not have a matching concurrent program.' );
  END IF;  
  
/*
  -- ============================================================================================
  -- specify the suffix of the conc program name if this is for special handling
  --   defaults to NULL, unless special handling parameter is TRUE
  -- ============================================================================================
  IF (p_special_handling) THEN
    lc_spec_handling_suffix := '_SPEC';
  END IF;

  -- ============================================================================================
  -- return data definition code based on detail level of mbs document
  -- ============================================================================================
  IF (lc_detail_level = 'SUMMARIZE') THEN
    RETURN 'XXARCBISUM' || lc_spec_handling_suffix;
  ELSIF (lc_detail_level = 'DETAIL') THEN
    RETURN 'XXARCBIDTL' || lc_spec_handling_suffix;
  ELSIF (lc_detail_level = 'HEADER') THEN
    RETURN 'XXARCBIHDR' || lc_spec_handling_suffix;
  ELSIF (lc_detail_level = 'ONE') THEN
    RETURN 'XXARCBIONE' || lc_spec_handling_suffix;
  ELSE
    RAISE_APPLICATION_ERROR
    ( -20001, 'The detail level "' || lc_detail_level ||
      '" for this document does not have a matching concurrent program.' );
  END IF;
*/

END;



-- ============================================================================================
-- Concurrent Program that handles the reprints of Consolidated Bills
-- ============================================================================================
PROCEDURE reprint_bill_document
( x_error_buffer            OUT    VARCHAR2,
  x_return_code             OUT    NUMBER,
  p_infocopy_flag           IN     VARCHAR2,   --Added for R1.2 Defect# 1210 CR# 466
  p_search_by               IN     VARCHAR2,   --Added for R1.2 Defect# 1210 CR# 466
  p_cust_account_id         IN     NUMBER,
  p_virtual_bill_flag       IN     VARCHAR2,   --Added for R1.2 Defect# 1210 CR# 466
  p_date_from               IN     VARCHAR2,   --Added for R1.2 Defect# 1210 CR# 466
  p_date_to                 IN     VARCHAR2,   --Added for R1.2 Defect# 1210 CR# 466
  p_dummy                   IN     VARCHAR2,   --Added for R1.2 Defect# 1210 CR# 466
  p_dummy1                  IN     VARCHAR2,   --Added for R1.2 Defect# 1210 CR# 466
  --p_cons_bill_num_from      IN     NUMBER,   -- Commented for for R1.2 Defect# 1210 CR# 466
  p_cons_bill_num_from      IN     VARCHAR2,   -- Added for for R1.2 Defect# 1210 CR# 466
  --p_cons_bill_num_to        IN     NUMBER,   -- Commented for for R1.2 Defect# 1210 CR# 466
  p_cons_bill_num_to        IN     VARCHAR2,   -- Added for for R1.2 Defect# 1210 CR# 466
  p_virtual_bill_num        IN     VARCHAR2,   --Added for R1.2 Defect# 1210 CR# 466
  p_multiple_bill           IN     VARCHAR2,   --Added for R1.2 Defect# 1210 CR# 466
  p_cust_doc_id             IN     NUMBER,     --Added for R1.2 Defect# 1210 CR# 466
  p_mbs_document_id         IN     NUMBER,
  p_override_doc_flag       IN     VARCHAR2,   --Added for R1.2 Defect# 1210 CR# 466
  p_email_option            IN     VARCHAR2,   --Added for R1.2 Defect# 1210 CR# 466
  p_dummy2                  IN     VARCHAR2,   --Added for R1.2 Defect# 1210 CR# 466
  p_email_address           IN     VARCHAR2,   --Added for R1.2 Defect# 1210 CR# 466
  p_special_handling        IN     VARCHAR2   DEFAULT 'N',
  p_mbs_extension_id        IN     NUMBER     DEFAULT NULL,
  p_request_id              IN     NUMBER     DEFAULT NULL,
  p_origin                  IN     VARCHAR2   DEFAULT NULL,
  --Start for the Defect # 12223
  p_doc_detail_cp           IN     VARCHAR2   DEFAULT NULL,
  p_doc_detail              IN     VARCHAR2   DEFAULT NULL,
  p_as_of_date1             IN     VARCHAR2   DEFAULT NULL,
  p_printer                 IN     VARCHAR2   DEFAULT NULL
  --End for the Defect # 12223
)
IS
  lc_sub_name        CONSTANT VARCHAR2(50)    := 'REPRINT_BILL_DOCUMENT';

  n_conc_request_id        NUMBER              DEFAULT NULL;

  b_sub_request            BOOLEAN             DEFAULT FALSE;

  b_success                BOOLEAN             DEFAULT NULL;
  
  b_called_subt            BOOLEAN             DEFAULT NULL;
  
  v_rpt_type               VARCHAR2(10)        DEFAULT NULL;

  v_conc_program_name      VARCHAR2(200)       DEFAULT NULL;
  v_xdo_template_code      VARCHAR2(200)       DEFAULT NULL;
  v_data_definition_app    VARCHAR2(200)       DEFAULT NULL;
  v_data_definition_code   VARCHAR2(200)       DEFAULT NULL;

  v_user_language          VARCHAR2(30)        DEFAULT NULL;
  v_user_territory         VARCHAR2(30)        DEFAULT NULL;

  v_return_msg             VARCHAR2(4000)      DEFAULT NULL;

  v_phase_code             VARCHAR2(30)        DEFAULT NULL;
  v_phase_desc             VARCHAR2(80)        DEFAULT NULL;
  v_status_code            VARCHAR2(30)        DEFAULT NULL;
  v_status_desc            VARCHAR2(80)        DEFAULT NULL;

  v_request_name           VARCHAR2(200)       DEFAULT NULL;
  p_rprn_req_id            NUMBER :=0;
  --p_caller                 VARCHAR2(20)        DEFAULT NULL;

--Start for the Defect# 12223

  lb_optional_printer      BOOLEAN;
  ln_number_copies         NUMBER :=0;
  lc_send_to               VARCHAR2(240)       DEFAULT NULL;
  lc_cm_text1              VARCHAR2(50)        DEFAULT NULL;  -- Added for Defect # 631 (CR : 662)
  lc_cm_text2              VARCHAR2(50)        DEFAULT NULL;  -- Added for Defect # 631 (CR : 662)
  lc_gift_card_text1       VARCHAR2(50)        DEFAULT NULL;  -- Added for Defect # 1451 (CR : 626)
  lc_gift_card_text2       VARCHAR2(50)        DEFAULT NULL;  -- Added for Defect # 1451 (CR : 626)
  lc_gift_card_text3       VARCHAR2(50)        DEFAULT NULL;  -- Added for Defect # 1451 (CR : 626)
  lc_error_location        VARCHAR(2000);
  lc_debug                 VArchar(1000);

--End for the Defect# 12223

--Start for for R1.2 Defect# 1210 CR# 466

 ln_doc_id                  xx_cdh_cust_acct_ext_b.n_ext_attr1%type;
 ln_attr_group_id           xx_cdh_cust_acct_ext_b.attr_group_id%type;

  CURSOR c_print
  ( cp_request_id     IN    NUMBER )
  IS
    SELECT fcpa.arguments printer,
           fcp.print_style style,
           fcpa.number_of_copies copies,
           fcp.save_output_flag save_output
      FROM fnd_concurrent_requests fcp,
           fnd_conc_pp_actions fcpa
     WHERE fcp.request_id = fcpa.concurrent_request_id
       AND fcpa.action_type = 1   -- printer options
       AND fcpa.status_s_flag = 'Y'
       AND fcp.request_id = cp_request_id
     ORDER BY fcpa.sequence;

  TYPE t_print_tab IS TABLE OF c_print%ROWTYPE
    INDEX BY BINARY_INTEGER;

  a_print_tab             t_print_tab;

  CURSOR c_layout
  ( cp_request_id     IN    NUMBER )
  IS
    SELECT fcpa.argument1 template_appl_name,
           fcpa.argument2 template_code,
           fcpa.argument3 template_language,
           fcpa.argument4 template_territory,
           fcpa.argument5 output_format
      FROM fnd_concurrent_requests fcp,
           fnd_conc_pp_actions fcpa
     WHERE fcp.request_id = fcpa.concurrent_request_id
       AND fcpa.action_type = 6   -- layout options
       AND fcpa.status_s_flag = 'Y'
       AND fcp.request_id = cp_request_id
     ORDER BY fcpa.sequence;

  TYPE t_layout_tab IS TABLE OF c_layout%ROWTYPE
    INDEX BY BINARY_INTEGER;

  a_layout_tab            t_layout_tab;

  CURSOR c_user_lang IS
    SELECT LOWER(iso_language) user_language,
           iso_territory user_territory
      FROM fnd_languages_vl
     WHERE language_code = FND_GLOBAL.CURRENT_LANGUAGE;

        CURSOR lcu_cust_email
   IS 
      SELECT HCP.email_address
      FROM   hz_cust_account_roles  HCAR
            ,hz_contact_points HCP
      WHERE  HCAR.cust_account_id      = P_CUST_ACCOUNT_ID
      AND    HCP.owner_table_id        = HCAR.party_id
      AND    HCP.owner_table_name      = 'HZ_PARTIES'
      AND    HCP.status                = 'A'
      AND    HCP.contact_point_type    = 'EMAIL'
      AND    HCP.contact_point_purpose ='BILLING'
      AND    HCAR.cust_acct_site_id    IS NULL
      AND    HCP.email_address         IS NOT NULL
      ORDER BY HCP.email_address;

   lc_user_mail_id        VARCHAR2(1200);
   lc_email_address       VARCHAR2(2400) := NULL;
   lc_email_body          VARCHAR2(2400);
   lc_email_from          VARCHAR2(2400);
   lc_email_subject       VARCHAR2(1000);
   lc_file_name           VARCHAR2(1000);
   ln_multi_trxno         NUMBER;
   ln_req_id              NUMBER;
   lc_mail_address        VARCHAR2(240);
   ln_count               NUMBER := 1;
   lc_exists              VARCHAR2(1);
   lc_message             VARCHAR2 (2000);
   lc_phase               VARCHAR2 (50);
   lc_status              VARCHAR2 (50);
   lc_dev_phase           VARCHAR2 (15);
   lc_dev_status          VARCHAR2 (15);
   lb_wait                BOOLEAN;
   ln_request_id_email    NUMBER;
   ln_request_id          NUMBER;
   -- End of changes for R1.2 Defect# 1210 CR# 466.
BEGIN
  -- ===========================================================================
  -- set child flag if this is a child request
  -- ===========================================================================
-- Added as part of 11993
lc_error_location := 'setting child flag if this is a child request'; 
lc_debug          := 'Concurrent request ID :'|| FND_GLOBAL.CONC_REQUEST_ID;

  IF (FND_GLOBAL.CONC_REQUEST_ID IS NOT NULL) THEN
   IF p_request_id IS NOT NULL THEN
     p_rprn_req_id :=p_request_id;
     --p_caller      :=p_origin;     
   ELSE
     p_rprn_req_id :=FND_GLOBAL.CONC_REQUEST_ID;
     --p_caller      :='RPRN';
   END IF; 
    b_sub_request := TRUE;
  END IF;

  -- ===========================================================================
  -- get the short concurrent program name for this mbs document id
  -- ===========================================================================
  -- Aded the below if condition of if-else for the Defect # 12223
-- Added as part of 11993
lc_error_location := 'getting the short concurrent program name for this mbs document id'; 
lc_debug          := 'document id :'|| FND_GLOBAL.CONC_REQUEST_ID || ' '||'special handling: ' || p_special_handling;
IF p_special_handling ='Y' THEN
  v_conc_program_name := p_doc_detail_cp;
ELSE

    -- Start for R1.2 Defect# 1210 CR# 466
    -- The below IF condition is handled to get the mbs doc id based on the cust_doc_id and override_mbs_flag as part of CR# 466.
    lc_error_location := 'Calculating the Document ID when Cust Doc ID is given and override_flag = N';
    lc_debug          := 'Cust Doc ID :' ||p_cust_doc_id;
    IF p_cust_doc_id IS NOT NULL AND p_override_doc_flag = 'N' THEN

       BEGIN

          SELECT attr_group_id
          INTO   ln_attr_group_id
          FROM   ego_attr_groups_v
          WHERE  attr_group_type = 'XX_CDH_CUST_ACCOUNT'
          AND    attr_group_name = 'BILLDOCS' ;

          SELECT n_ext_attr1
          INTO   ln_doc_id
          FROM   xx_cdh_cust_acct_ext_b  -- Removed xxcrm schema Reference
          WHERE  n_ext_attr2     = p_cust_doc_id
          AND    attr_group_id   = ln_attr_group_id
          AND    cust_account_id = p_cust_account_id;

       EXCEPTION
       WHEN OTHERS THEN
          ln_doc_id := p_mbs_document_id;
          x_return_code  := 1;
          x_error_buffer := SQLERRM;
          fnd_file.put_line(fnd_file.log , 'Since exception occurs we are going to use the document id from the parameter and not from the Customer Set up');
          fnd_file.put_line(fnd_file.log , 'Error While: ' || lc_error_location||' '|| SQLERRM);
          fnd_file.put_line(fnd_file.log , 'Debug:' || lc_debug);
       END;

    ELSE

       ln_doc_id := p_mbs_document_id;

    END IF;

    -- End for R1.2 Defect# 1210 CR# 466

  v_conc_program_name :=
    get_conc_program_name
    ( --p_mbs_document_id  => p_mbs_document_id, -- Commented for R1.2 Defect# 1210 CR# 466
       p_mbs_document_id  => ln_doc_id
      ,p_special_handling => FALSE );
END IF;
  -- ===========================================================================
  -- get the default value for the XML Publisher data definition application
  --   short name from the parameter on the given concurrent program
  -- ===========================================================================
  -- Added as part of 11993
lc_error_location := 'getting the default value for the XML Publisher data definition application'; 
lc_debug          := NULL;
  
  v_data_definition_app :=
    get_param_default_value
    ( p_conc_program_name  => v_conc_program_name,
      p_parameter_name     => 'DataTemplateApplShortName' );

  -- ===========================================================================
  -- get the default value for the XML Publisher data definition code from the
  --   parameter on the given concurrent program
  -- ===========================================================================
   -- Added as part of 11993
lc_error_location := 'getting the default value for the XML Publisher data definition code from the parameter on the given concurrent program'; 
lc_debug          := NULL;
  v_data_definition_code :=
    get_param_default_value
    ( p_conc_program_name  => v_conc_program_name,
      p_parameter_name     => 'DataTemplateCode' );

  -- ===========================================================================
  -- if called from special handling, need data template to contain the
  --   special handling suffix, otherwise we use the name of the conc
  --   program short name (for version 1.1 changes)
  -- ===========================================================================
     -- =============================================   
     -- Below code commented for Defect 5689 
   -- ===============================================    
  /* 
  IF (p_special_handling = 'Y') THEN
    v_data_definition_code := v_data_definition_code || GC_SPEC_HANDLING_SUFFIX;
  ELSE
    v_data_definition_code := v_data_definition_code;
  END IF;
  */
   -- =====================================   
   -- Below code fix is for Defect 5689 
   -- =====================================      
    v_data_definition_code := v_data_definition_code;
  -- ===========================================================================
  -- get this concurrent program's print options, and set them on the child
  -- ===========================================================================
  IF (b_sub_request) THEN
    OPEN c_print
    ( cp_request_id  => p_rprn_req_id );    --( cp_request_id  => FND_GLOBAL.CONC_REQUEST_ID ); Defect 11134
      -- Added as part of 11993
            lc_error_location := 'getting this concurrent programs print options, and set them on the child'; 
            lc_debug          := NULL;

    
    FETCH c_print
     BULK COLLECT
     INTO a_print_tab;
    CLOSE c_print;

    IF (a_print_tab.COUNT > 0) THEN
      FOR i_index IN a_print_tab.FIRST..a_print_tab.LAST LOOP
        IF (i_index = a_print_tab.FIRST) THEN
          b_success :=
            FND_REQUEST.set_print_options
            ( printer         => a_print_tab(i_index).printer,
              style           => a_print_tab(i_index).style,
              copies          => a_print_tab(i_index).copies,
              save_output     => (a_print_tab(i_index).save_output = 'Y'),
              print_together  => 'N');

             ln_number_copies := a_print_tab(i_index).copies;   -- Added for Defect # 12223

        ELSE
          b_success :=
            FND_REQUEST.add_printer
            ( printer         => a_print_tab(i_index).printer,
              copies          => a_print_tab(i_index).copies );
        END IF;
      END LOOP;
    END IF;
  END IF;

-- Start for Defect # 12223

  IF (p_printer IS NOT NULL) THEN
             lb_optional_printer := FND_REQUEST.add_printer(
                                       printer         => p_printer
                                      ,copies          => ln_number_copies );
   FND_FILE.PUT_LINE(FND_FILE.LOG, 'Printer Name :'||p_printer);
  END IF;

  IF (lb_optional_printer = TRUE) THEN
     FND_FILE.PUT_LINE(FND_FILE.LOG, 'Return Value from 2nd Printer Options Set: '||'TRUE');
  ELSE
     FND_FILE.PUT_LINE(FND_FILE.LOG, 'Return Value from 2nd Printer Options Set: '||'FALSE');
  END IF;

  BEGIN
-- commented as a part of defect 11993
    /*    SELECT XFTV.source_value6
        INTO   lc_send_to
        FROM   xx_fin_translatevalues XFTV
              ,xx_fin_translatedefinition XFTD
        WHERE  XFTV.translate_id    = XFTD.translate_id
        AND    XFTD.translation_name = 'OD_AR_BILLING_SOURCE_EXCL'
        AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
        AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
        AND    XFTV.enabled_flag = 'Y'
        AND    XFTD.enabled_flag = 'Y';*/

-- added for defect 11993

      -- Added as part of 11993
            lc_error_location := 'getting this concurrent programs print options, and set them on the child'; 
            lc_debug          := NULL;
        
        SELECT description
        INTO lc_send_to
        FROM fnd_lookup_values_vl          -- Removed apps schema Reference
        WHERE lookup_type='OD_AR_SPECIAL_HANDLING'
        AND lookup_code='SEND_TO'
        AND enabled_flag='Y'
        AND trunc(SYSDATE) BETWEEN TRUNC(start_date_active) AND TRUNC(NVL(end_date_active,SYSDATE+1));
        
        
  EXCEPTION
        WHEN NO_DATA_FOUND THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'No data found in Translation to the Send To Field');
            lc_send_to := '******';
        WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others Exception : Send To Translation');
            lc_send_to := '******';
  END;
-- End for Defect # 12223

-- Start for Defect # 631 (CR 662)
     BEGIN

        SELECT  SUBSTR(description,1,50)
        INTO    lc_cm_text1
        FROM    fnd_lookup_values_vl -- Removed apps schema Reference
        WHERE   lookup_type='OD_BILLING_CM_LINE_TEXT'
        AND     lookup_code='TEXT1'
        AND     enabled_flag='Y'
        AND     TRUNC(SYSDATE) BETWEEN TRUNC(start_date_active) AND TRUNC(NVL(end_date_active,SYSDATE+1));

     EXCEPTION 
        WHEN NO_DATA_FOUND THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'No data found in lookup OD_BILLING_CM_LINE_TEXT to the TEXT1 To Field');
            lc_cm_text1 := NULL;
        WHEN OTHERS THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others Exception : TEXT1 -> OD_BILLING_CM_LINE_TEXT lookup');
             lc_cm_text1 := NULL;
     END;

     BEGIN

        SELECT  SUBSTR(description,1,50)
        INTO    lc_cm_text2
        FROM    fnd_lookup_values_vl   -- Removed apps schema Reference
        WHERE   lookup_type='OD_BILLING_CM_LINE_TEXT'
        AND     lookup_code='TEXT2'
        AND     enabled_flag='Y'
        AND     trunc(SYSDATE) BETWEEN TRUNC(start_date_active) AND TRUNC(NVL(end_date_active,SYSDATE+1));

     EXCEPTION 
        WHEN NO_DATA_FOUND THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'No data found in lookup OD_BILLING_CM_LINE_TEXT to the TEXT2 To Field');
            lc_cm_text2 := NULL;
        WHEN OTHERS THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others Exception : TEXT2 -> OD_BILLING_CM_LINE_TEXT lookup');
             lc_cm_text2 := NULL;
     END;

-- End for Defect # 631 (CR 662)

-- Start for Defect # 1451 (CR 626)
     BEGIN

        SELECT  SUBSTR(description,1,50)
        INTO    lc_gift_card_text1
        FROM    fnd_lookup_values_vl  -- Removed apps schema Reference
        WHERE   lookup_type    = 'OD_BILLING_TENDER_PAYMENT_TEXT'
        AND     lookup_code    = 'TEXT1'
        AND     enabled_flag   = 'Y'
        AND     TRUNC(SYSDATE) BETWEEN TRUNC(start_date_active) AND TRUNC(NVL(end_date_active,SYSDATE+1));

     EXCEPTION 
        WHEN NO_DATA_FOUND THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'No data found in lookup OD_BILLING_TENDER_PAYMENT_TEXT to the TEXT1 To Field');
           lc_gift_card_text1 := NULL;
        WHEN OTHERS THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others Exception : TEXT1 -> OD_BILLING_TENDER_PAYMENT_TEXT lookup');
           lc_gift_card_text1 := NULL;
     END;

     BEGIN

        SELECT  SUBSTR(description,1,50)
        INTO    lc_gift_card_text2
        FROM    fnd_lookup_values_vl       -- Removed apps schema Reference
        WHERE   lookup_type    = 'OD_BILLING_TENDER_PAYMENT_TEXT'
        AND     lookup_code    = 'TEXT2'
        AND     enabled_flag   = 'Y'
        AND     trunc(SYSDATE) BETWEEN TRUNC(start_date_active) AND TRUNC(NVL(end_date_active,SYSDATE+1));

     EXCEPTION 
        WHEN NO_DATA_FOUND THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'No data found in lookup OD_BILLING_TENDER_PAYMENT_TEXT to the TEXT2 To Field');
           lc_gift_card_text2 := NULL;
        WHEN OTHERS THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others Exception : TEXT2 -> OD_BILLING_TENDER_PAYMENT_TEXT lookup');
           lc_gift_card_text2 := NULL;
     END;

     BEGIN

        SELECT  SUBSTR(description,1,50)
        INTO    lc_gift_card_text3
        FROM    fnd_lookup_values_vl  -- Removed apps schema Reference
        WHERE   lookup_type    = 'OD_BILLING_TENDER_PAYMENT_TEXT'
        AND     lookup_code    = 'TEXT3'
        AND     enabled_flag   = 'Y'
        AND     trunc(SYSDATE) BETWEEN TRUNC(start_date_active) AND TRUNC(NVL(end_date_active,SYSDATE+1));

     EXCEPTION 
        WHEN NO_DATA_FOUND THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'No data found in lookup OD_BILLING_TENDER_PAYMENT_TEXT to the TEXT3 To Field');
           lc_gift_card_text3 := NULL;
        WHEN OTHERS THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others Exception : TEXT3 -> OD_BILLING_TENDER_PAYMENT_TEXT lookup');
           lc_gift_card_text3 := NULL;
     END;

-- End for Defect # 1451 (CR 626)

  -- ===========================================================================
  -- get this concurrent program's layout, and set them on the child
  -- ===========================================================================
  -- IF (b_sub_request) THEN
  --   OPEN c_layout
  --   ( cp_request_id  => FND_GLOBAL.CONC_REQUEST_ID );
  --   FETCH c_layout
  --    BULK COLLECT
  --    INTO a_layout_tab;
  --   CLOSE c_layout;
  --
  --   IF (a_layout_tab.COUNT > 0) THEN
  --     FOR i_index IN a_layout_tab.FIRST..a_layout_tab.LAST LOOP
  --       b_success :=
  --         FND_REQUEST.add_layout
  --         ( template_appl_name    => a_layout_tab(i_index).template_appl_name,
  --           template_code         => a_layout_tab(i_index).template_code,
  --           template_language     => a_layout_tab(i_index).template_language,
  --           template_territory    => a_layout_tab(i_index).template_territory,
  --           output_format         => a_layout_tab(i_index).output_format );
  --     END LOOP;
  --   END IF;
  --END IF;


  -- ===========================================================================
  -- get the user's current language and territory
  -- ===========================================================================
      -- Added as part of 11993
            lc_error_location := 'getting the users current language and territory'; 
            lc_debug          := NULL;


  OPEN c_user_lang;
  FETCH c_user_lang
   INTO v_user_language,
        v_user_territory;
  CLOSE c_user_lang;

  -- ===========================================================================
  -- Based on new billing redesign, we will use just three templates
  -- to print both REPRINTS and SPECIAL HANDLING. The templates are
  -- XXARCBIONE, XXARCBISUM and XXARCBIDTL.
  -- We will not use the templates we designed earlier with an _SPEC.
  -- ===========================================================================
   v_xdo_template_code := v_conc_program_name;
   
       -- =============================================   
       -- Below code commented for Defect 8657 
       -- =============================================  
  /*
    IF (p_special_handling = 'Y') THEN
       v_xdo_template_code := v_conc_program_name || GC_SPEC_HANDLING_SUFFIX;
    ELSE
       v_xdo_template_code := v_conc_program_name;
    END IF;
  */

  -- ===========================================================================
  -- get the layout based on the conc program name and add it to the child
  -- ===========================================================================
  
        -- Added as part of 11993
            lc_error_location := 'getting the layout based on the conc program name and add it to the child'; 
            lc_debug          := NULL;
  b_success :=
    FND_REQUEST.add_layout
    ( template_appl_name    => GC_APPL_SHORT_NAME,
      template_code         => v_xdo_template_code,
      template_language     => v_user_language,
      template_territory    => v_user_territory,
      output_format         => GC_XDO_TEMPLATE_FORMAT );

  -- ===========================================================================
  -- submit the request
  -- ===========================================================================
--Added if condition of if-else and Modified the else part for Defect # 12223
        -- Added as part of 11993
            lc_error_location := 'Submit request - Reprint program'; 
            lc_debug          := 'Special Handling Flag '||p_special_handling;

IF p_special_handling ='Y' THEN

  n_conc_request_id :=
    FND_REQUEST.submit_request
    ( application    => GC_APPL_SHORT_NAME,      -- application short name
      program        => v_conc_program_name,     -- concurrent program name
      description    => NULL,                    -- addl request description
      start_time     => NULL,                    -- request submit time
      sub_request    => b_sub_request,           -- is this a sub-request?
      argument1      => v_data_definition_app,   -- Data Definition App Name
      argument2      => v_data_definition_code,  -- Data Definition Code
      argument3      => NULL,       -- Customer Name
      argument4      => p_cons_bill_num_from,    -- From Summary Bill
      argument5      => p_cons_bill_num_to,      -- To Summary Bill
      argument6      => NULL,       -- MBS Document Id
      argument7      => p_special_handling,      -- Special Handling Flag   
      argument8      => NULL,      -- MBS Extension Id
      argument9      => p_rprn_req_id,           -- Request ID
      argument10     => p_origin,               --Caller [Original Special Handling or Reprints].
      argument11     => p_as_of_date1,
      argument12     => p_doc_detail,
      argument13     => lc_send_to,
      argument14     => 'Y',  --Added Debug parameter
      argument15     => lc_cm_text1,   -- Added for Defect # 631 (CR : 662)
      argument16     => lc_cm_text2,    -- Added for Defect # 631 (CR : 662)
      argument17     => lc_gift_card_text1, -- Added for Defect # 1451 (CR : 626)
      argument18     => lc_gift_card_text2, -- Added for Defect # 1451 (CR : 626)
      argument19     => lc_gift_card_text3, -- Added for Defect # 1451 (CR : 626)
      --Start for R1.2 Defect# 1210 CR# 466
      argument20     => NULL,
      argument21     => NULL,
      argument22     => NULL,
      argument23     => NULL,
      argument24     => NULL,
      argument25     => NULL,
      argument26     => NULL,
      argument27     => NULL,
      argument28     => NULL
      --End for R1.2 Defect# 1210 CR# 466
      );
     
ELSE

  n_conc_request_id :=
    FND_REQUEST.submit_request
    ( application    => GC_APPL_SHORT_NAME,      -- application short name
      program        => v_conc_program_name,     -- concurrent program name
      description    => NULL,                    -- addl request description
      start_time     => NULL,                    -- request submit time
      sub_request    => b_sub_request,           -- is this a sub-request?
      argument1      => v_data_definition_app,   -- Data Definition App Name
      argument2      => v_data_definition_code,  -- Data Definition Code
      argument3      => p_cust_account_id,       -- Customer Name
      argument4      => p_cons_bill_num_from,    -- From Summary Bill
      --argument5      => p_cons_bill_num_to,      -- To Summary Bill -- Commented for R1.2 Defect@ 1210 CR# 466
      argument5      => p_cons_bill_num_from,      -- To Summary Bill -- Added for R1.2 Defect# 1210 CR# 466
      --argument6      => p_mbs_document_id,       -- MBS Document Id -- Commented for R1.2 Defect# 1210 CR# 466
      argument6      => ln_doc_id,               --MBS Document ID  -- Added for R1.2 Defect# 1210 CR# 466
      argument7      => p_special_handling,      -- Special Handling Flag   
      argument8      => p_mbs_extension_id,      -- MBS Extension Id
      argument9      => p_rprn_req_id,           -- Request ID
      argument10     => p_origin,               --Caller [Original Special Handling or Reprints].
      argument11     => NULL,
      argument12     => NULL,
      argument13     => lc_send_to,
      argument14     => 'Y',  --Added Debug parameter
      argument15     => lc_cm_text1,   -- Added for Defect # 631 (CR : 662)
      argument16     => lc_cm_text2,   -- Added for Defect # 631 (CR : 662)
      argument17     => lc_gift_card_text1, -- Added for Defect # 1451 (CR : 626)
      argument18     => lc_gift_card_text2, -- Added for Defect # 1451 (CR : 626)
      argument19     => lc_gift_card_text3, -- Added for Defect # 1451 (CR : 626)
      --Start for R1.2 Defect# 1210 CR# 466
      argument20     => p_infocopy_flag,
      argument21     => p_virtual_bill_flag,
      argument22     => p_virtual_bill_num,
      argument23     => p_multiple_bill,
      argument24     => p_date_from,
      argument25     => p_date_to,
      argument26     => p_email_option,
      argument27     => p_email_address,
      argument28     => p_cust_doc_id
      --End for R1.2 Defect# 1210 CR# 466
    );

END IF;

  -- ===========================================================================
  -- if request was successful
  -- ===========================================================================
  IF (n_conc_request_id > 0) THEN
    -- ===========================================================================
    -- if a child request, then update it for concurrent mgr to process
    -- ===========================================================================
        -- Added as part of 11993
            lc_error_location := 'Update fnd_concurrent_requests '; 
            lc_debug          := 'Request ID '||n_conc_request_id;
    
    IF (b_sub_request) THEN
      UPDATE fnd_concurrent_requests
         SET phase_code = 'P'
             ,status_code = 'I'
             ,last_updated_by    = FND_GLOBAL.USER_ID  -- added for defect 4761
             ,last_update_date   = SYSDATE               -- added for defect 4761
       WHERE request_id = n_conc_request_id;
    END IF;

    -- ===========================================================================
    -- must commit work so that the concurrent manager polls the request
    -- ===========================================================================
    COMMIT;

    -- Start of changes for R1.2 Defect# 1210 CR# 466.
    IF p_special_handling = 'N' THEN

       lb_wait := fnd_concurrent.wait_for_request ( n_conc_request_id
                                                   ,10
                                                   ,NULL
                                                   ,lc_phase
                                                   ,lc_status
                                                   ,lc_dev_phase
                                                   ,lc_dev_status
                                                   ,lc_message
                                                   );

          BEGIN

             lc_error_location := 'Fetching the Email address if Email Option is User or Both';
             lc_debug          := NULL;

             SELECT text
             INTO   lc_email_subject
             FROM   ar_standard_text_vl
             WHERE  name = 'OD_BILLING_REPRINT_SUBJECT';
            
             SELECT text
             INTO   lc_email_body
             FROM   ar_standard_text_vl
             WHERE  name = 'OD_BILLING_REPRINT_BODY';

             SELECT text
             INTO   lc_email_from
             FROM   ar_standard_text_vl
             WHERE  name = 'OD_BILLING_REPRINT_FROM';

             IF P_EMAIL_OPTION IN ('User','Both') THEN
                SELECT email_address
                INTO   lc_user_mail_id
                FROM   fnd_user  -- Removed apps schema Reference
                WHERE  user_id = apps.fnd_profile.value('USER_ID');
             END IF;

             lc_error_location := 'Fetching the Email address if Email Option is Customer or Both';
             lc_debug          := NULL;

             IF P_EMAIL_OPTION IN ('Customer','Both') THEN

                FOR rec IN lcu_cust_email
                LOOP

                   IF ln_count = 1 THEN
                      lc_email_address := rec.email_address;
                   ELSE
                      lc_email_address := lc_email_address ||','||rec.email_address;
                   END IF;

                   ln_count := ln_count + 1;

                END LOOP;

             END IF;

             lc_error_location := 'Concatenating the Email option for different Options';
             lc_debug          := NULL;

             IF P_EMAIL_OPTION = 'Both' THEN
                lc_mail_address := lc_email_address||','||lc_user_mail_id;
             ELSIF P_EMAIL_OPTION = 'Customer' THEN
                lc_mail_address := lc_email_address;
             ELSIF P_EMAIL_OPTION = 'User' THEN
                lc_mail_address := lc_user_mail_id;
             ELSIF P_EMAIL_OPTION = 'Others' THEN
                lc_mail_address := P_EMAIL_ADDRESS;
             END IF;

             lc_error_location := 'Submitting the emailer program.';
             lc_debug          := NULL;
             fnd_file.put_line(fnd_file.log , 'n_conc_request_id :'||n_conc_request_id);
             fnd_file.put_line(fnd_file.log , 'p_request_id :'||p_request_id);

             ln_request_id := FND_GLOBAL.CONC_REQUEST_ID;

             SELECT 'Y'
             INTO   lc_exists
             FROM   dual
             WHERE  EXISTS (SELECT 1
                            FROM   xx_ar_cbi_rprn_trx_history
                            WHERE  request_id = ln_request_id
                            );

             fnd_file.put_line(fnd_file.log , 'lc_mail_address :'||lc_mail_address);
             fnd_file.put_line(fnd_file.log , 'lc_exists :'||lc_exists);

             IF P_MULTIPLE_BILL IS NOT NULL THEN
                ln_multi_trxno := INSTR(P_MULTIPLE_BILL,',');
             ELSE
                ln_multi_trxno := 0;
             END IF;

             fnd_file.put_line(fnd_file.log , 'p_cons_bill_num_from '||p_cons_bill_num_from);
             fnd_file.put_line(fnd_file.log , 'p_virtual_bill_num ' ||p_virtual_bill_num);

             IF p_cons_bill_num_from IS NOT NULL THEN
               lc_file_name := 'bill_no_'||p_cons_bill_num_from||'_Reprint.PDF';
             ELSIF p_virtual_bill_num IS NOT NULL THEN
               lc_file_name := 'bill_no_'||SUBSTR(p_virtual_bill_num,1,instr(p_virtual_bill_num,'-')-1)||'_Reprint.PDF';
             ELSIF ln_multi_trxno > 0 THEN
                lc_file_name := P_CUST_ACCOUNT_ID||'_Reprint.PDF'; 
             ELSIF P_CUST_ACCOUNT_ID IS NOT NULL AND P_CONS_BILL_NUM_FROM IS NULL AND P_VIRTUAL_BILL_NUM IS NULL AND P_MULTIPLE_BILL IS NULL THEN
                lc_file_name := P_CUST_ACCOUNT_ID||'_Reprint.PDF'; 
             ELSE
                   lc_file_name := P_MULTIPLE_BILL||'_Reprint.PDF';
             END IF;

             fnd_file.put_line(fnd_file.log , 'lc_file_name ' ||lc_file_name);
             fnd_file.put_line(fnd_file.log , 'lc_mail_address submit '||lc_mail_address);

             IF lc_exists = 'Y' AND lc_mail_address IS NOT NULL THEN

                ln_request_id_email := fnd_request.submit_request( 'XXFIN'
                                                                  ,'XXODINDREPMAILER'
                                                                  ,NULL
                                                                  ,NULL
                                                                  ,FALSE
                                                                  ,lc_mail_address
                                                                  ,lc_email_subject
                                                                  ,lc_email_body
                                                                  ,n_conc_request_id
                                                                  ,lc_file_name
                                                                  ,lc_email_from
                                                                  );

             END IF;

             COMMIT;

             IF NVL(ln_request_id_email,0) = 0 THEN
                fnd_file.put_line(fnd_file.log , 'Email Program Submition Failed');
             ELSE
                fnd_file.put_line(fnd_file.log , 'Email Program Submition Completed Successfully');
             END IF;
          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                lc_exists := 'N';
                fnd_file.put_line(fnd_file.log , 'Email Program Submition Failed - No Data');

          END;

       END IF;

    -- End of changes for R1.2 Defect# 1210 CR# 466.

    put_log_line( ' Concurrent Request ID: ' || n_conc_request_id || '.' );

  -- ===========================================================================
  -- else errors have occured for request
  -- ===========================================================================
  ELSE
    -- ===========================================================================
    -- retrieve and raise any errors
    -- ===========================================================================
    --FND_MESSAGE.retrieve( v_return_msg );
    FND_MESSAGE.raise_error;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    x_return_code := 2;
    x_error_buffer := SQLERRM;
  fnd_file.put_line(fnd_file.log , 'Error While: ' || lc_error_location||' '|| SQLERRM);
  fnd_file.put_line(fnd_file.log , 'Debug:' || lc_debug);
    XX_COM_ERROR_LOG_PUB.log_error
    ( p_program_type            => 'CONCURRENT PROGRAM',
      p_program_name            => 'XX_AR_CONS_BILL_PKG',
      p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID,
      p_module_name             => 'AR',
      p_error_location          => 'Reprint Summary Bill Document',
      p_error_message_count     => 1,
      p_error_message_code      => 'E',
      p_error_message           => SQLERRM,
      p_error_message_severity  => 'Major',
      p_notify_flag             => 'N',
      p_object_type             => lc_sub_name );
    RAISE;
END;



-- ============================================================================================
-- Concurrent Program that handles the special handling printing of Consolidated Bills
-- ============================================================================================
PROCEDURE print_special_handling_docs
( x_error_buffer            OUT    VARCHAR2,
  x_return_code             OUT    NUMBER,
  p_as_of_date              IN     VARCHAR2   DEFAULT TO_CHAR(TRUNC(SYSDATE),'YYYY/MM/DD HH24:MI:SS'),
  p_optional_printer        IN     VARCHAR2   DEFAULT NULL  --Added for Defect # 12223
)
IS
  lc_sub_name        CONSTANT VARCHAR2(50)    := 'PRINT_SPECIAL_HANDLING';

  lc_bill_num_from         VARCHAR2(200)       DEFAULT NULL;
  lc_bill_num_to           VARCHAR2(200)       DEFAULT NULL;

  ld_as_of_date            DATE                DEFAULT TRUNC(NVL(TO_DATE(p_as_of_date,'YYYY/MM/DD HH24:MI:SS'),SYSDATE));
                                                 -- FND_CONC_DATE.string_to_date();

  ld_print_date            VARCHAR2(40)        DEFAULT TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS');

  ln_group_number          NUMBER              DEFAULT NULL;
  lb_new_group             BOOLEAN             DEFAULT TRUE;
  ln_req_id                NUMBER :=0;
  lc_error_location        VARCHAR2(2000);     -- added for defect 11993
  lc_debug                 VARCHAR2(1000);     -- added for defect 11993


--Commented for the Defect 13576, 13577 and 13578. Base table is used instead of view
  /*CURSOR c_bills(p_doc_detail_level VARCHAR2) IS  --Added Cursor parameter for the Defect # 12223
    SELECT aci.customer_id,
           xcdm.document_id,
           xcdm.doc_detail_level,
           aci.cons_inv_id,
           aci.cons_billing_number,
           xceb.extension_id
      FROM ar_cons_inv_all aci,
           xx_cdh_a_ext_billdocs_v xceb,
           xx_cdh_mbs_document_master xcdm
     WHERE 1 =1
       AND aci.customer_id             =xceb.cust_account_id
       AND xceb.billdocs_doc_id        =xcdm.document_id
       AND xceb.billdocs_doc_type      ='Consolidated Bill'
       AND xceb.billdocs_delivery_meth ='PRINT'
       AND xceb.billdocs_paydoc_ind    ='Y'           -- only include pay docs
       AND xcdm.doc_detail_level       = p_doc_detail_level  -- Added for Defect # 12223
       AND (aci.attribute2 IS NULL AND aci.attribute4 IS NULL AND aci.attribute10 IS NULL) -- only records not already processed
       AND aci.status                  ='ACCEPTED'
       AND xceb.billdocs_special_handling IS NOT NULL   -- only records flagged as special handling
       AND XX_AR_INV_FREQ_PKG.compute_effective_date    -- only within effective date
              --        ( xceb.billdocs_payment_term, TRUNC(aci.cut_off_date)) <= ld_as_of_date  commented for defect 11993
           ( xceb.billdocs_payment_term, TRUNC(aci.cut_off_date-1)) <= ld_as_of_date   -- added for defect 11993
       AND  EXISTS
            (
              SELECT 1
              FROM   ar_cons_inv_trx_lines
              WHERE  cons_inv_id =aci.cons_inv_id
            )
     ORDER BY aci.cons_billing_number;  --Added for Defect # 12223
     */
--End of Change for the Defect 13576, 13577 and 13578.

--Added for the Defect 13576, 13577 and 13578. Base table is used instead of view

    CURSOR c_bills( p_doc_detail_level VARCHAR2
                   ,p_attr_group_id    NUMBER)
    IS
       SELECT  ACI.customer_id
              ,XCDM.document_id
              ,XCDM.doc_detail_level
              ,ACI.cons_inv_id
              ,ACI.cons_billing_number
              ,XCCAE.extension_id
         FROM  ar_cons_inv_all                  ACI
              ,xx_cdh_cust_acct_ext_b     XCCAE -- Removed xxcrm schema Reference
              ,xx_cdh_mbs_document_master XCDM
        WHERE 1                           = 1
        AND   ACI.customer_id             = XCCAE.cust_account_id
        AND   XCCAE.attr_group_id         = p_attr_group_id
        AND   XCCAE.n_ext_attr1           = XCDM.document_id
        AND   XCCAE.c_ext_attr1           ='Consolidated Bill'
        AND   XCCAE.c_ext_attr3           ='PRINT'
        AND   XCCAE.c_ext_attr2           ='Y'
        AND   XCDM.doc_detail_level       = p_doc_detail_level
        AND   (ACI.attribute2 IS NULL AND ACI.attribute4 IS NULL AND ACI.attribute10 IS NULL AND ACI.attribute15 IS NULL)   -- Added attribute15 FOR r1.4 cr# 586
        AND   ACI.status                  ='ACCEPTED'
        AND   XCCAE.c_ext_attr4 IS NOT NULL
        -- Commented for Defect# 15063.
        /*AND   XX_AR_INV_FREQ_PKG.compute_effective_date
              (XCCAE.c_ext_attr14, TRUNC(ACI.cut_off_date-1)) <= ld_as_of_date*/
        -- Added for Defect# 15063.
        AND   XX_AR_INV_FREQ_PKG.compute_effective_date
              (XCCAE.c_ext_attr14, TO_DATE(ACI.attribute1)-1) <= ld_as_of_date
        AND    EXISTS
               (
                 SELECT 1
                 FROM   ar_cons_inv_trx_lines
                 WHERE  cons_inv_id = ACI.cons_inv_id
               )
-- Added the below conditions for R1.3 CR 738 Defect 2766
        AND   ld_as_of_date               >= XCCAE.d_ext_attr1
        AND   (XCCAE.d_ext_attr2          IS NULL
               OR
               ld_as_of_date              <= XCCAE.d_ext_attr2) 
-- End of changes for R1.3 CR 738 Defect 2766
       ORDER BY ACI.cons_billing_number;
--End of Change for the Defect 13576, 13577 and 13578.

-- Start of Defect # 12223

-- Start of Defect # 12223

  TYPE t_bills_tab IS TABLE OF c_bills%ROWTYPE
    INDEX BY PLS_INTEGER;

  l_bills_tab                  t_bills_tab;
  ln_doc_count                 NUMBER := 1;
  lc_doc_detail_level          xx_cdh_mbs_document_master.doc_detail_level%TYPE;
  lc_doc_detail_cp             VARCHAR2(15);
  ln_attr_group_id             NUMBER;

-- End of Defect # 12223

BEGIN

 ln_req_id :=fnd_global.conc_request_id;
  -- ============================================================================================
  -- retrieve all the effective summary bills with special handling
  -- ============================================================================================

  SELECT attr_group_id
  INTO   ln_attr_group_id
  FROM   ego_attr_groups_v
  WHERE  attr_group_type = 'XX_CDH_CUST_ACCOUNT'
  AND    attr_group_name = 'BILLDOCS' ;

put_log_line('Global Conc Request ID : '||FND_GLOBAL.CONC_REQUEST_ID);

 LOOP  -- Added the loop for the Defect # 12223
-- Start of changes for R1.2 Defect # 3300 CR 619

 /*-- Start of Defect # 12223
  IF ln_doc_count = 1 THEN
     lc_doc_detail_level := 'ONE';
     lc_doc_detail_cp := 'XXARCBIONE';
  ELSIF ln_doc_count = 2 THEN
     lc_doc_detail_level := 'SUMMARIZE';
     lc_doc_detail_cp := 'XXARCBISUM';
  ELSIF ln_doc_count = 3 THEN
     lc_doc_detail_level := 'DETAIL';
     lc_doc_detail_cp := 'XXARCBIDTL';
  ELSE NULL;
  END IF;*/
----  End of Defect # 12223 */ Commented for defect # 3300
IF ln_doc_count = 1 THEN
     lc_doc_detail_level := 'ONE';
     lc_doc_detail_cp := 'XXARCBIONEPRINT';
  ELSIF ln_doc_count = 2 THEN
     lc_doc_detail_level := 'SUMMARIZE';
     lc_doc_detail_cp := 'XXARCBISUMPRINT';
  ELSIF ln_doc_count = 3 THEN
     lc_doc_detail_level := 'DETAIL';
     lc_doc_detail_cp := 'XXARCBIDTLPRINT';
  ELSE NULL;
  END IF;
-- End of changes for R1.2 Defect # 3300 CR 619


   lc_error_location := 'Getting consolidated bill and customer document details';    -- added for defect 11993 
   lc_debug := 'Doc Detail Level ' || lc_doc_detail_level;
  OPEN c_bills(lc_doc_detail_level,ln_attr_group_id);
  
   FETCH c_bills
   BULK COLLECT
   INTO l_bills_tab;
  CLOSE c_bills;

  put_log_line('');
  put_log_line(lc_doc_detail_level);
  put_log_line('---------------');
  put_log_line(l_bills_tab.COUNT || ' summary bill(s) found.' );
  -- ============================================================================================
  -- default group number
  -- ============================================================================================
  lb_new_group := TRUE;
  ln_group_number := 0;

  -- ============================================================================================
  -- loop through all special handling summary bills if any exist
  -- ============================================================================================
  IF (l_bills_tab.COUNT > 0) THEN
       lc_bill_num_from    := l_bills_tab(l_bills_tab.first).cons_billing_number;
       lc_bill_num_to   := l_bills_tab(l_bills_tab.last).cons_billing_number;
       put_log_line('Summary Bill From= '||lc_bill_num_from||'  --  '||'Summary Bill To= '||lc_bill_num_to);

  --Commented for the Defect # 12223
/*    FOR i_index IN l_bills_tab.FIRST..l_bills_tab.LAST LOOP
      put_log_line('');
      put_log_line(' Summary Bill= ' || l_bills_tab(i_index).cons_billing_number );
      put_log_line('');
      
        lc_bill_num_from := l_bills_tab(i_index).cons_billing_number;
        lc_bill_num_to   := l_bills_tab(i_index).cons_billing_number;      
*/      
     /*
      -- ============================================================================================
      -- if new group
      -- ============================================================================================
      IF (lb_new_group) THEN   --i_index = l_bills_tab.FIRST) THEN
        ln_group_number := ln_group_number + 1;
        lc_bill_num_from := l_bills_tab(i_index).cons_billing_number;
        lc_bill_num_to := l_bills_tab(i_index).cons_billing_number;
        lb_new_group := FALSE;
      END IF;

      -- ============================================================================================
      -- if this bill is last of group (customer or detail level), start next group
      -- ============================================================================================
      IF (i_index > l_bills_tab.FIRST AND i_index < l_bills_tab.LAST) THEN
        IF (l_bills_tab(i_index).customer_id <> l_bills_tab(i_index+1).customer_id
          AND l_bills_tab(i_index).doc_detail_level <> l_bills_tab(i_index+1).doc_detail_level )
        THEN
          lc_bill_num_to := l_bills_tab(i_index-1).cons_billing_number;
          lb_new_group := TRUE;
        END IF;
      -- ============================================================================================
      -- last record, so has to be last of group (and no more groups are left)
      -- ============================================================================================
      ELSIF (i_index > l_bills_tab.FIRST AND i_index = l_bills_tab.LAST) THEN
        lc_bill_num_to := l_bills_tab(i_index-1).cons_billing_number;
      END IF;
     */
      -- ============================================================================================
      -- update the consolidated bill as being printed
      --   attribute10 = PRINT_DATE | REQUEST_ID | GROUP_NUMBER
      -- ============================================================================================
--Commented for Defect # 12223
/*      UPDATE ar_cons_inv
         SET attribute10 = ld_print_date || '|' ||FND_GLOBAL.CONC_REQUEST_ID
       WHERE cons_inv_id = l_bills_tab(i_index).cons_inv_id;
*/         /*
               ld_print_date || '|' ||
                             FND_GLOBAL.CONC_REQUEST_ID || '|' ||
                             ln_group_number
         */                             

      -- ===========================================================================
      -- print special handling summary bills
      -- ===========================================================================
       lc_error_location := 'calling reprint_bill_document procedure for special handling ';    -- added for defect 11993 
       lc_debug := NULL;
      reprint_bill_document
      ( x_error_buffer            => x_error_buffer,
        x_return_code             => x_return_code,
        p_infocopy_flag           => NULL,             -- Added for R1.2 Defect# 1210 CR# 466
        p_search_by               => NULL,              --Added for R1.2 Defect# 1210 CR# 466
        p_cust_account_id         => NULL,
        p_virtual_bill_flag       => NULL,              -- Added for R1.2 Defect# 1210 CR# 466
        p_dummy                   => NULL,              -- Added for R1.2 Defect# 1210 CR# 466
        p_dummy1                  => NULL,              -- Added for R1.2 Defect# 1210 CR# 466
        p_cons_bill_num_from      => lc_bill_num_from,
        p_cons_bill_num_to        => lc_bill_num_to,
        p_virtual_bill_num        => NULL,              -- Added for R1.2 Defect# 1210 CR# 466
        p_multiple_bill           => NULL,              -- Added for R1.2 Defect# 1210 CR# 466
        p_date_from               => NULL,              -- Added for R1.2 Defect# 1210 CR# 466
        p_date_to                 => NULL,              -- Added for R1.2 Defect# 1210 CR# 466
        p_cust_doc_id             => NULL,              -- Added for R1.2 Defect# 1210 CR# 466
        p_mbs_document_id         => NULL,
        p_override_doc_flag       => NULL,              -- Added for R1.2 Defect# 1210 CR# 466
        p_email_option            => NULL,              -- Added for R1.2 Defect# 1210 CR# 466
        p_dummy2                  => NULL,              -- Added for R1.2 Defect# 1210 CR# 466
        p_email_address           => NULL,              -- Added for R1.2 Defect# 1210 CR# 466
        p_special_handling        => 'Y',
        p_mbs_extension_id        => NULL,
        p_request_id              => ln_req_id,
        p_origin                  => 'ORIG_SPEC',
      --Start for Defect # 12223
        p_doc_detail_cp           => lc_doc_detail_cp,
        p_doc_detail              => lc_doc_detail_level,
        p_as_of_date1             => ld_as_of_date,
        p_printer                 => p_optional_printer
      --End for the Defect # 12223
      );
    --END LOOP;  commented for Defect # 12223
  END IF;

--Start for Defect # 12223
  ln_doc_count := ln_doc_count + 1;
  EXIT WHEN ln_doc_count=4;
 END LOOP;
--End for Defect # 12223

EXCEPTION
  WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log , 'Error While: ' || lc_error_location||' '|| SQLERRM);
  fnd_file.put_line(fnd_file.log , 'Debug:' || lc_debug);
    x_return_code := 2;
    x_error_buffer := SQLERRM;
END;

-- Added the below procedure REPRINT_CBI_DOC_WRAP as part of R1.2 Defect# 1210 CR# 466.
-- +===================================================================+
-- | Name : REPRINT_CBI_DOC_WRAP                                       |
-- | Description : 1. This is used to submit the Consolidated reprint  |
-- |                 program for each separate CBI bills in multiple   |
-- |                 CBI number parameter if customer number is not    |
-- |                 passed.                                           |
-- |               2. If customer number is passed then only one       |
-- |                 CBI reprint program will be submitted even in case|
-- |                 of multiple CBI number parameter is passed.       |
-- |                                                                   |
-- | Program :OD: AR Reprint Summary Bills - Main                      |
-- |                                                                   |
-- | Returns  : x_error_buff,x_ret_code                                |
-- +===================================================================+

 PROCEDURE REPRINT_CBI_DOC_WRAP ( x_error_buffer            OUT    VARCHAR2
                                 ,x_return_code             OUT    NUMBER
                                 ,p_infocopy_flag           IN     VARCHAR2
                                 ,p_search_by               IN     VARCHAR2
                                 ,p_cust_account_id         IN     NUMBER
                                 ,p_virtual_bill_flag       IN     VARCHAR2
                                 ,p_date_from               IN     VARCHAR2
                                 ,p_date_to                 IN     VARCHAR2
                                 ,p_dummy                   IN     VARCHAR2
                                 ,p_dummy1                  IN     VARCHAR2
                                 ,p_cons_bill_num_from      IN     VARCHAR2
                                 ,p_cons_bill_num_to        IN     VARCHAR2
                                 ,p_virtual_bill_num        IN     VARCHAR2
                                 ,p_multiple_bill           IN     VARCHAR2
                                 ,p_cust_doc_id             IN     NUMBER
                                 ,p_mbs_document_id         IN     NUMBER
                                 ,p_override_doc_flag       IN     VARCHAR2
                                 ,p_email_option            IN     VARCHAR2
                                 ,p_dummy2                  IN     VARCHAR2
                                 ,p_email_address           IN     VARCHAR2
                                 ,p_special_handling        IN     VARCHAR2   DEFAULT 'N'
                                 ,p_mbs_extension_id        IN     NUMBER     DEFAULT NULL
                                 ,p_request_id              IN     NUMBER     DEFAULT NULL
                                 ,p_origin                  IN     VARCHAR2   DEFAULT NULL
                                 ,p_doc_detail_cp           IN     VARCHAR2   DEFAULT NULL
                                 ,p_doc_detail              IN     VARCHAR2   DEFAULT NULL
                                 ,p_as_of_date1             IN     VARCHAR2   DEFAULT NULL
                                 ,p_printer                 IN     VARCHAR2   DEFAULT NULL
                                )
 IS

    lc_multi_trans_num VARCHAR2(1000);
    ln_loop            NUMBER;
    ln_instr_len       NUMBER;
    lc_value           VARCHAR2(1000);
    ln_request_id      NUMBER;
    ln_cust_acct_id    NUMBER;

 BEGIN

    IF ((p_cust_account_id IS NOT NULL) OR (p_multiple_bill IS NULL)) THEN

       ln_request_id := FND_REQUEST.SUBMIT_REQUEST( 'XXFIN'
                                                   ,'XXARRPSUMMBILL'
                                                   ,NULL
                                                   ,NULL
                                                   ,FALSE
                                                   ,p_infocopy_flag
                                                   ,p_search_by
                                                   ,p_cust_account_id
                                                   ,p_virtual_bill_flag
                                                   ,p_date_from
                                                   ,p_date_to
                                                   ,p_dummy
                                                   ,p_dummy1
                                                   ,p_cons_bill_num_from
                                                   ,p_cons_bill_num_to
                                                   ,p_virtual_bill_num
                                                   ,p_multiple_bill
                                                   ,p_cust_doc_id
                                                   ,p_mbs_document_id
                                                   ,p_override_doc_flag
                                                   ,p_email_option
                                                   ,p_dummy2
                                                   ,p_email_address
                                                   ,p_special_handling
                                                   ,p_mbs_extension_id
                                                   ,p_request_id
                                                   ,p_origin
                                                   ,p_doc_detail_cp
                                                   ,p_doc_detail
                                                   ,p_as_of_date1
                                                   ,p_printer
                                                   );

       COMMIT;

    ELSE

       lc_multi_trans_num := p_multiple_bill;

       SELECT LENGTH(lc_multi_trans_num) - LENGTH(TRANSLATE(lc_multi_trans_num,CHR(0)||',',CHR(0)))
       INTO   ln_loop
       FROM   dual;

       ln_loop := ln_loop + 1;

       FOR i IN 1..ln_loop
       LOOP

          SELECT INSTR(lc_multi_trans_num,',')
          INTO   ln_instr_len
          FROM   dual;

          SELECT  SUBSTR(lc_multi_trans_num,1,ln_instr_len-1)
                 ,SUBSTR(lc_multi_trans_num,ln_instr_len+1)
          INTO    lc_value
                 ,lc_multi_trans_num
          FROM  dual;

          IF lc_value IS NULL THEN
             lc_value := lc_multi_trans_num;
          END IF;

          -- For Performance Deriving Customer ID

          IF (p_virtual_bill_flag ='N') THEN
             SELECT aci.customer_id 
             INTO ln_cust_acct_id 
             FROM ar_cons_inv_all aci  -- Removed apps schema Reference
             WHERE aci.cons_billing_number = lc_value;
          ELSE 
             BEGIN
               SELECT DISTINCT XACBH.customer_id 
               INTO ln_cust_acct_id
               FROM xx_ar_cons_bills_history_all XACBH  -- Removed apps schema Reference
               WHERE attribute16 = lc_value;
             EXCEPTION
             WHEN NO_DATA_FOUND THEN
                        SELECT DISTINCT XAGBLA.customer_id
                        INTO ln_cust_acct_id 
                        FROM  xx_ar_gen_bill_lines_all  XAGBLA
                        WHERE XAGBLA.n_ext_attr2 = lc_value;
             WHEN OTHERS THEN
                  fnd_file.put_line(fnd_file.log ,'ERROR :Not Able to Derive the Customer ID'||SQLERRM);
            END;
    END IF;             
          ln_request_id := FND_REQUEST.SUBMIT_REQUEST( 'XXFIN'
                                                      ,'XXARRPSUMMBILL'
                                                      ,NULL
                                                      ,NULL
                                                      ,FALSE
                                                      ,p_infocopy_flag
                                                      ,p_search_by
                                                      ,ln_cust_acct_id
                                                      ,p_virtual_bill_flag
                                                      ,p_date_from
                                                      ,p_date_to
                                                      ,p_dummy
                                                      ,p_dummy1
                                                      ,p_cons_bill_num_from
                                                      ,p_cons_bill_num_to
                                                      ,p_virtual_bill_num
                                                      ,lc_value
                                                      ,p_cust_doc_id
                                                      ,p_mbs_document_id
                                                      ,p_override_doc_flag
                                                      ,p_email_option
                                                      ,p_dummy2
                                                      ,p_email_address
                                                      ,p_special_handling
                                                      ,p_mbs_extension_id
                                                      ,p_request_id
                                                      ,p_origin
                                                      ,p_doc_detail_cp
                                                      ,p_doc_detail
                                                      ,p_as_of_date1
                                                      ,p_printer
                                                      );

          COMMIT;

       END LOOP;

       COMMIT;

    END IF;

 END REPRINT_CBI_DOC_WRAP;

END;
/