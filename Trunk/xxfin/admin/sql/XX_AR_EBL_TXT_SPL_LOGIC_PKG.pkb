CREATE OR REPLACE PACKAGE BODY XX_AR_EBL_TXT_SPL_LOGIC_PKG
AS
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_grand_total                                                     |
-- | Description : This function is used to get the total invoice amount for the       |
-- |               given file_id and cust_doc_id                                       |
-- |Parameters   : cust_doc_id, file_id                                                |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version               |
-- |                                               (Master Defect#37585)               |
-- |      1.1 15-Dec-2017  Aniket J      CG        Requirement# (22772)                |
-- +===================================================================================+
    FUNCTION get_grand_total (p_cust_doc_id IN NUMBER
                               ,p_file_id IN NUMBER
                               ,p_org_id  IN NUMBER
                               ,p_field_name IN VARCHAR2
                               ,p_fun_combo_whr          IN VARCHAR2  DEFAULT NULL  --Added by Aniket CG #22772 on 15 Dec 2017
                               )
    RETURN NUMBER IS
      ln_total_inv_amt NUMBER;

    BEGIN
  
       SELECT SUM(original_invoice_amount)
      INTO ln_total_inv_amt
      FROM xx_ar_ebl_cons_hdr_main
      WHERE cust_doc_id = p_cust_doc_id
      AND file_id = p_file_id
      AND org_id = p_org_id
      -- start Added by Aniket CG #22772 on 15 Dec 2017
      and (transaction_class =  nvl(regexp_substr(p_fun_combo_whr, '[^,]+', 1, 1) ,transaction_class ) 
          or  transaction_class =  regexp_substr(p_fun_combo_whr, '[^,]+', 1, 2)) ;
      -- end Added by Aniket CG #22772 on 15 Dec 2017          
      RETURN ln_total_inv_amt;
    EXCEPTION WHEN OTHERS THEN
      RETURN 0;
    END;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_grand_freight_amt                                               |
-- | Description : This function is used to get the total freight amount for           |
-- |               the given file_id and cust_doc_id                                   |
-- |Parameters   : cust_doc_id, file_id                                                |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version               |
-- |      1.1 15-Dec-2017  Aniket J      CG        Requirement# (22772)                   |
-- +===================================================================================+
    FUNCTION get_grand_freight_amt (p_cust_doc_id IN NUMBER
                               ,p_file_id IN NUMBER
                               ,p_org_id  IN NUMBER
                               ,p_field_name IN VARCHAR2
                               ,p_fun_combo_whr          IN VARCHAR2 DEFAULT NULL    --Added by Aniket CG #22772 on 15 Dec 2017
                               )
    RETURN NUMBER IS
      ln_total_freight_amt NUMBER;
    BEGIN
      SELECT SUM(total_freight_amount)
      INTO ln_total_freight_amt
      FROM xx_ar_ebl_cons_hdr_main
      WHERE cust_doc_id = p_cust_doc_id
      AND file_id = p_file_id
      AND org_id = p_org_id
         -- start Added by Aniket CG #22772 on 15 Dec 2017
      and (transaction_class =  nvl(regexp_substr(p_fun_combo_whr, '[^,]+', 1, 1) ,transaction_class ) 
          or  transaction_class =  regexp_substr(p_fun_combo_whr, '[^,]+', 1, 2)) ;
         -- end Added by Aniket CG #22772 on 15 Dec 2017
      RETURN ln_total_freight_amt;
    EXCEPTION WHEN OTHERS THEN
      RETURN 0;
    END;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_grand_misc_amt                                                  |
-- | Description : This function is used to get the total miscellaneous amount for the |
-- |               given file_id and cust_doc_id                                       |
-- |Parameters   : cust_doc_id, file_id                                                |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version               |
-- +===================================================================================+
    FUNCTION get_grand_misc_amt (p_cust_doc_id IN NUMBER
                               ,p_file_id IN NUMBER
                               ,p_org_id  IN NUMBER
                               ,p_field_name IN VARCHAR2
                               )
    RETURN NUMBER IS
      ln_total_misc_amt NUMBER;
    BEGIN
      SELECT total_misc_amt
      INTO ln_total_misc_amt
      FROM xx_ar_ebl_file
      WHERE cust_doc_id = p_cust_doc_id
      AND file_id = p_file_id
      AND org_id = p_org_id;
      RETURN ln_total_misc_amt;
    EXCEPTION WHEN OTHERS THEN
      RETURN 0;
    END;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_grand_tax_amt                                                   |
-- | Description : This function is used to get the total tax amount for the           |
-- |               given file_id and cust_doc_id                                       |
-- |Parameters   : cust_doc_id, file_id                                                |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version               |
-- +===================================================================================+
    FUNCTION get_grand_tax_amt (p_cust_doc_id IN NUMBER
                               ,p_file_id IN NUMBER
                               ,p_org_id  IN NUMBER
                               ,p_field_name IN VARCHAR2
                               )
    RETURN NUMBER IS
      ln_total_tax_amt NUMBER;
    BEGIN
      SELECT total_sales_tax_amt
      INTO ln_total_tax_amt
      FROM xx_ar_ebl_file
      WHERE cust_doc_id = p_cust_doc_id
      AND file_id = p_file_id
      AND org_id = p_org_id;
      RETURN ln_total_tax_amt;
    EXCEPTION WHEN OTHERS THEN
      RETURN 0;
    END;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_grand_gift_card_amt                                             |
-- | Description : This function is used to get the total tax amount for the           |
-- |               given file_id and cust_doc_id                                       |
-- |Parameters   : cust_doc_id, file_id                                                |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version               |
-- +===================================================================================+
    FUNCTION get_grand_gift_card_amt (p_cust_doc_id IN NUMBER
                               ,p_file_id IN NUMBER
                               ,p_org_id  IN NUMBER
                               ,p_field_name IN VARCHAR2
                               )
    RETURN NUMBER IS
      ln_total_gift_card_amt NUMBER;
    BEGIN
      SELECT total_gift_card_amt
      INTO ln_total_gift_card_amt
      FROM xx_ar_ebl_file
      WHERE cust_doc_id = p_cust_doc_id
      AND file_id = p_file_id
      AND org_id = p_org_id;
      RETURN ln_total_gift_card_amt;
    EXCEPTION WHEN OTHERS THEN
      RETURN 0;
    END;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_dist_class                                                      |
-- | Description : This function is used to build the query to get the                 |
-- |               Distribution Class from Cost Center Code                            |
-- |               given file_id and cust_doc_id                                       |
-- |Parameters   : cust_doc_id, file_id                                                |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version               |
-- +===================================================================================+
    FUNCTION get_dist_class (p_cust_doc_id IN NUMBER
                            ,p_file_id IN NUMBER
                            ,p_org_id  IN NUMBER
                            ,p_field_name IN VARCHAR2
                            )
    RETURN VARCHAR2 IS
      lc_dist_class  VARCHAR2(1000);
      ln_cust_num    NUMBER;
      ln_cust_number VARCHAR2(20);
      lc_source_field_name  VARCHAR2(100);
      ln_start_position     NUMBER;
      ln_end_position       NUMBER;
      lc_default_value      VARCHAR2(100);
    BEGIN
      -- Get the Customer Number from cust_doc_id
      SELECT account_number
      INTO ln_cust_num
      FROM hz_cust_accounts_all hcaa,
           xx_cdh_cust_acct_ext_b xccaeb
      WHERE xccaeb.cust_account_id = hcaa.cust_account_id
      AND xccaeb.n_ext_attr2 = p_cust_doc_id;
      --ln_cust_num := 431076;
      SELECT xftv.source_value1 cust_number
            ,xftv.source_value3 source_field_name
            ,xftv.target_value3 start_position
            ,xftv.target_value4 end_position
            ,xftv.target_value5 default_value
      INTO ln_cust_number
          ,lc_source_field_name
          ,ln_start_position
          ,ln_end_position
          ,lc_default_value
      FROM xx_fin_translatedefinition xftd
          ,xx_fin_translatevalues xftv
      WHERE xftd.translate_id = xftv.translate_id
      AND xftd.translation_name ='XX_AR_EBL_TXT_SPL_LOGIC'
      AND xftv.target_value2 = p_field_name
      AND xftv.source_value1 = ln_cust_num
      and xftv.enabled_flag='Y'
      AND TRUNC(SYSDATE) BETWEEN TRUNC(xftv.start_date_active) AND TRUNC(NVL(xftv.end_date_active,SYSDATE+1));

      lc_dist_class := 'DECODE(LENGTH(SUBSTR('||lc_source_field_name||','||ln_start_position||','||ln_end_position||'))'||','||
                       'NULL'||','||'''00000'''||','||'substr('||lc_source_field_name||','||ln_start_position||','||ln_end_position||'))';
      RETURN lc_dist_class;
    EXCEPTION WHEN OTHERS THEN
      RETURN 'NULL';
    END;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_current_seq_num                                                 |
-- | Description : This function is used to build the query to get the                 |
-- |               Distribution Class from Cost Center Code                            |
-- |               given file_id and cust_doc_id                                       |
-- |Parameters   : p_cust_doc_id, p_file_id, p_org_id, p_field_name                    |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version               |
-- +===================================================================================+
    FUNCTION get_current_seq_num (p_cust_doc_id IN NUMBER
                            ,p_file_id IN NUMBER
                            ,p_org_id  IN NUMBER
                            ,p_field_name IN VARCHAR2
                            )
    RETURN NUMBER IS
      ln_field_id  NUMBER;
      ln_current_value NUMBER;
    BEGIN
      BEGIN
        SELECT xftv.source_value1
        INTO ln_field_id
        FROM xx_fin_translatedefinition xftd
            ,xx_fin_translatevalues xftv
        WHERE xftd.translate_id = xftv.translate_id
        AND xftd.translation_name ='XX_CDH_EBL_TXT_DET_FIELDS'
        AND xftv.source_value4 = 'SEQUENCE_NUM'
        AND xftv.enabled_flag='Y'
        AND TRUNC(SYSDATE) BETWEEN TRUNC(xftv.start_date_active) AND TRUNC(NVL(xftv.end_date_active,SYSDATE+1));
      EXCEPTION WHEN OTHERS THEN
        ln_field_id := NULL;
      END;
      BEGIN
        SELECT DISTINCT seq_start_val
        INTO ln_current_value
        FROM xx_cdh_ebl_templ_dtl_txt
        WHERE cust_doc_id = p_cust_doc_id
        AND field_id = ln_field_id;
      EXCEPTION WHEN OTHERS THEN
        ln_current_value := NULL;
      END;
      RETURN ln_current_value;
    EXCEPTION WHEN OTHERS THEN
      RETURN NULL;
    END;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_total_inv_lines                                                 |
-- | Description : This function is used to get the total invoice lines counts for the |
-- |               given file_id and cust_doc_id                                       |
-- |Parameters   : cust_doc_id, file_id                                                |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version               |
-- +===================================================================================+
    FUNCTION get_total_inv_lines (p_cust_doc_id IN NUMBER
                               ,p_file_id IN NUMBER
                               ,p_org_id  IN NUMBER
                               ,p_field_name IN VARCHAR2
                               )
    RETURN NUMBER IS
      ln_total_inv_lines NUMBER;
    BEGIN
      SELECT COUNT(1)
      INTO ln_total_inv_lines
      FROM xx_ar_ebl_txt_dtl_stg
      WHERE file_id = p_file_id
      AND cust_doc_id = p_cust_doc_id
      AND rec_type != 'FID';
      RETURN ln_total_inv_lines;
    EXCEPTION WHEN OTHERS THEN
      RETURN 0;
    END;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_quarter_num                                                     |
-- | Description : This function is used to get the Calender year Quarter Number       |
-- |               from the Invoice Bill Date for the given file_id and cust_doc_id    |
-- |Parameters   : cust_doc_id, file_id                                                |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version               |
-- +===================================================================================+
    FUNCTION get_quarter_num (p_cust_doc_id IN NUMBER
                               ,p_file_id IN NUMBER
                               ,p_org_id  IN NUMBER
                               ,p_field_name IN VARCHAR2
                               )
    RETURN VARCHAR2 IS
      ln_quarter_num VARCHAR2(2);
      lc_month VARCHAR2(3);
    BEGIN
      BEGIN
        SELECT DISTINCT TO_CHAR(INVOICE_BILL_DATE,'MON')
        INTO lc_month
        FROM xx_ar_ebl_cons_hdr_main
        WHERE file_id = p_file_id
        AND cust_doc_id = p_cust_doc_id;
      EXCEPTION WHEN OTHERS THEN
        lc_month := NULL;
      END;
      IF lc_month IN ('JAN','FEB','MAR') THEN
        ln_quarter_num := '01';
      ELSIF lc_month IN ('APR','MAY','JUN') THEN
        ln_quarter_num := '02';
      ELSIF lc_month IN ('JUL','AUG','SEP') THEN
        ln_quarter_num := '03';
      ELSIF lc_month IN ('OCT','NOV','DEC') THEN
        ln_quarter_num := '04';
      END IF;

      RETURN ln_quarter_num;
    EXCEPTION WHEN OTHERS THEN
      RETURN NULL;
    END;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_requestor_first_name                                            |
-- | Description : This function is used to get the first name of the contact name     |
-- |               for the given file_id and cust_doc_id                               |
-- |Parameters   : cust_doc_id, file_id                                                |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version               |
-- +===================================================================================+
    FUNCTION get_requestor_first_name (p_cust_doc_id IN NUMBER
                               ,p_file_id IN NUMBER
                               ,p_org_id  IN NUMBER
                               ,p_field_name IN VARCHAR2
                               )
    RETURN VARCHAR2 IS
      lc_requestor_first_name VARCHAR2(500);
    BEGIN
        lc_requestor_first_name := 'SUBSTR(hdr.bill_to_contact_name,1,instr(hdr.bill_to_contact_name,'||''' '''||')-1)';
        RETURN lc_requestor_first_name;
    EXCEPTION WHEN OTHERS THEN
      RETURN 'NULL';
    END;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_total_inv_lines                                                 |
-- | Description : This function is used to get the total invoice lines counts for the |
-- |               given file_id and cust_doc_id ( Dummy Function)                     |
-- |Parameters   : cust_doc_id, file_id                                                |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 03-MAY-2018  Aniket J                Initial draft version #NAIT-36070   |
-- +===================================================================================+
    FUNCTION get_total_rec_count (p_cust_doc_id IN NUMBER
                               ,p_file_id IN NUMBER
                               ,p_org_id  IN NUMBER
                               ,p_field_name IN VARCHAR2
                               )
    RETURN NUMBER IS
      ln_total_lines NUMBER;
      ln_total_hdr NUMBER;
      ln_total_dtl NUMBER;
      ln_total_trl NUMBER;
    BEGIN
    
   -- IF p_field_name is null then 
      SELECT COUNT(1)
      INTO ln_total_dtl
      FROM xx_ar_ebl_txt_dtl_stg
      WHERE file_id = p_file_id
      AND cust_doc_id = p_cust_doc_id
      AND rec_type != 'FID';
      
      SELECT COUNT(1)
      INTO ln_total_hdr
      FROM xx_ar_ebl_txt_hdr_stg
      WHERE file_id = p_file_id
      AND cust_doc_id = p_cust_doc_id
      AND rec_type != 'FID';
      
      SELECT COUNT(1)
      INTO ln_total_trl
      FROM xx_ar_ebl_txt_trl_stg
      WHERE file_id = p_file_id
      AND cust_doc_id = p_cust_doc_id
      AND rec_type != 'FID';
     
     ln_total_lines := ln_total_dtl +ln_total_hdr +ln_total_trl ;
      
      RETURN ln_total_lines;
     EXCEPTION WHEN OTHERS THEN
      RETURN 0;
    END;	
 END XX_AR_EBL_TXT_SPL_LOGIC_PKG;
/
SHOW ERRORS;
EXIT;
