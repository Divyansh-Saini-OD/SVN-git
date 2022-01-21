SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON
SET DEFINE OFF

PROMPT Creating PACKAGE BODY XX_SALES_TAX_REPORT_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_SALES_TAX_REPORT_PKG

-- +===========================================================v========+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name : Sales Tax Reporting Interface                              |
-- | Rice ID : I0431                                                   |
-- | Description : This feeds all the transactions from the Oracle     |
-- |               E-Business to Vertex, for Sales Reporting and filing|
-- |               tax returns                                         |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   ===============      =======================|
-- |1.0       13-JAN-2009     Lincy K           Initial version        |
-- |1.1       07-FEB-2009    Aravind A.         Performance changes    |
-- | 1.2     16-Feb-2009     Subbu Pillai      Changed POS and AOPS conditions and modified the logic for Subtotal in AOPS |
-- | 1.3     17-Feb-2009     Subbu Pillai      Changed the logic to derive the Tax Exempt Amount and Sub Total for AOPS |
-- |                                           Changed the logic to derive the Tax exempt amount for POS
-- |                                                                   |
-- |1.4       18-APR-2009    Aravind A.         Defect 14240           |
-- |1.5       10-MAR-2011    Sinon Perlas       Modify program for SDR |
-- |                                            project                |
-- |1.6	  26-JUN-2012    Sinon Perlas		    Defect 17016 - Report  |
-- |                                            on POS Single Payment  |
-- |1.7   06-MAR-2014        Deepak V           Defect 28579 - Hint added for performance issue.
-- |                                            Changed qry to use dba_sequence instead of max on ar_posting_control
-- |1.8   10-Mar-2014      Jay Gupta            Changed the HINT       |   
-- |1.9   28-May-2014      Ray Strauss          Defect 30267           |
-- |                                            replaced control_id logic and added GL_DATE condition to main extract SQL
-- |2.0   18-AUG-16        Punita Kumari        Defect#38309- Added condition 
-- |                                            before updating translation value
-- |2.1   21-AUG-17        Rohit Nanda          Defect#43065- Changed hint as per engineering team suggestion for
-- |                                            Performance improvement
-- +===================================================================+

 AS
   gc_file_name          VARCHAR2(100);
   gt_file               UTL_FILE.FILE_TYPE;
   gc_pos_dest_file      VARCHAR2(100) := 'TAXF300PO';
   gc_aops_dest_file     VARCHAR2(100) := 'TAXF301PO';
	gc_sob_ids            VARCHAR2(100) := '';
	gc_batch_source_ids   VARCHAR2(100) := '';
-- +===================================================================+
-- | Name       : SALES_TAX                                            |
-- | Parameters : p_order_type ,p_file_path,p_cycle_date ,p_debug      |
-- | Returns    : Return Code                                          |
-- |              Error Message                                        |
-- +===================================================================+

   PROCEDURE SALES_TAX (    x_error_buff       OUT  VARCHAR2
                            ,x_ret_code        OUT  NUMBER
                            ,p_order_type      IN   VARCHAR2
                            ,p_file_path       IN   VARCHAR2
                            ,p_cycle_date      IN   VARCHAR2
                            ,p_debug           IN   VARCHAR2
                       )
   AS

   lc_filedata               VARCHAR2(200);
   lc_company                xx_fin_translatevalues.source_value1%TYPE;
   lc_source_file_path       VARCHAR2(500);
   lc_source_file_name       VARCHAR2(100);
   lc_dest_file_name         VARCHAR2(100);
   ln_req_id                 NUMBER;
   ln_buffer                 BINARY_INTEGER := 32767;

   lc_file_open              CHAR := 'N';
   lc_record_exist           CHAR := 'N';
   lc_last_day_flag          CHAR := 'N';
   lc_cycle_day              VARCHAR2(10);
   lc_first_day              VARCHAR2(10);
   lc_last_day               VARCHAR2(10);
   lc_utl_source             VARCHAR2(30);
   lc_file_mode              VARCHAR2(1);
   lc_comp                   VARCHAR2(30);
   lc_pre_comp               VARCHAR2(30);
   lc_pos_id                 VARCHAR2(30);

   --For POS display

   lc_tax_amt_sign           VARCHAR2(1);
   lc_taxable_amt_sign       VARCHAR2(1);
   lc_non_taxable_amt_sign   VARCHAR2(1);
   lc_tax_exempt_amt_sign    VARCHAR2(1);
   lc_disc_amt_sign          VARCHAR2(1);

   ln_sum_tax_amt            NUMBER:=0;
   ln_sum_taxable_amt        NUMBER:=0;
   ln_sum_non_taxable_amt    NUMBER:=0;
   ln_sum_tax_exempt_amt     NUMBER:=0;
   ln_sum_disc_amt           NUMBER:=0;

   --For AOPS display

   lc_aops_tax_amt_sign      VARCHAR2(1);
   lc_aops_subtot_amt_sign   VARCHAR2(1);
   lc_aops_tax_exe_amt_sign  VARCHAR2(1);
   lc_aops_disc_amt_sign     VARCHAR2(1);

   ln_sum_sub_tot            NUMBER;
   ln_aops_tax_amt           NUMBER;
   ln_aops_subtot_amt        NUMBER;
   ln_aops_tax_exe_amt       NUMBER;
   ln_aops_disc_amt          NUMBER;

   --Defect 14240
   ln_max_wait_int           NUMBER := 2;
   ln_max_wait_time          NUMBER := 60;
   lc_phase                  VARCHAR2(50) := NULL;
   lc_status                 VARCHAR2(50) := NULL;
   lc_devphase               VARCHAR2(50) := NULL;
   lc_devstatus              VARCHAR2(50) := NULL;
   lc_message                VARCHAR2(50) := NULL;
   lb_req_status             BOOLEAN := FALSE;

   TYPE lcu_trx_ref IS REF CURSOR;
   trx_ref_type     lcu_trx_ref;


-- +===================================================================+
-- | Name       : TWE_UTL_FILE                                         |
-- +===================================================================+

    PROCEDURE twe_utl_file(p_order      IN  VARCHAR2
                           ,x_file_mode OUT VARCHAR2)
    IS
    ld_cycle_date        DATE;
    BEGIN

      ld_cycle_date := FND_DATE.CANONICAL_TO_DATE(p_cycle_date);
      SELECT TO_CHAR(TO_DATE(ld_cycle_date,'DD-MON-RR'),'DAY')
      INTO lc_cycle_day
      FROM dual;

      lc_cycle_day := TRIM(lc_cycle_day);

      lc_utl_source := p_order||'_FILE_NAME';

      --Query to fetch the first day of week

      SELECT XFTV.target_value1
      INTO lc_first_day
      FROM   xx_fin_translatedefinition XFTD
             ,xx_fin_translatevalues XFTV
      WHERE  XFTD.translate_id = XFTV.translate_id
      AND    XFTD.translation_name = 'AR_SALESTAX_DETAILS'
      AND    XFTV.source_value1 = 'FIRST_DAY'
      AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
      AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
      AND    XFTV.enabled_flag = 'Y'
      AND    XFTD.enabled_flag = 'Y';

      IF (p_debug = 'Y') THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Day of Cycle run is                    : '||lc_cycle_day);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'First Day from Translation is          : '||lc_first_day);
      END IF;

      IF (lc_cycle_day = lc_first_day) THEN
           gc_file_name := 'AR_TRANS_'||p_order||'_'||TO_CHAR(ld_cycle_date,'YYYYMMDD')||'.'||'txt';
           x_file_mode := 'w';

           UPDATE (SELECT XFTV.target_value1
                   FROM   xx_fin_translatevalues XFTV
                          ,xx_fin_translatedefinition XFTD
                   WHERE  XFTV.source_value1 = lc_utl_source
                   AND    XFTD.translate_id = XFTV.translate_id
                   AND    XFTD.translation_name = 'AR_SALESTAX_DETAILS')
           SET target_value1 = gc_file_name;

           IF (p_debug = 'Y') THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Translation value for '|| lc_utl_source ||' is updated with File Name : '||gc_file_name);
           END IF;

      ELSE

           SELECT XFTV.target_value1
           INTO gc_file_name
           FROM   xx_fin_translatedefinition XFTD
                  ,xx_fin_translatevalues XFTV
           WHERE  XFTD.translate_id = XFTV.translate_id
           AND    XFTD.translation_name = 'AR_SALESTAX_DETAILS'
           AND    XFTV.source_value1 = lc_utl_source
           AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
           AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
           AND    XFTV.enabled_flag = 'Y'
           AND    XFTD.enabled_flag = 'Y';

           x_file_mode := 'a';

          IF gc_file_name IS NULL THEN
                  gc_file_name := 'AR_TRANS_'||p_order||'_'||TO_CHAR(ld_cycle_date,'YYYYMMDD')||'.'||'txt';
                  x_file_mode := 'w';


                  UPDATE (SELECT XFTV.target_value1
                          FROM   xx_fin_translatevalues XFTV
                                 ,xx_fin_translatedefinition XFTD
                          WHERE  XFTV.source_value1 = lc_utl_source
                          AND    XFTD.translate_id = XFTV.translate_id
                          AND    XFTD.translation_name = 'AR_SALESTAX_DETAILS')
                  SET target_value1 = gc_file_name;

          END IF;
      END IF;

      IF (p_debug = 'Y') THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Extract File Name for current run is   : '||gc_file_name);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'File open pattern is                   : '||x_file_mode);
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
           gc_file_name := 'AR_TRANS_'||p_order||'_'||TO_CHAR(ld_cycle_date,'YYYYMMDD')||'.'||'txt';
           x_file_mode := 'w';
    END;


-- +===================================================================+
-- | Name       : TWE_POS_PRC                                          |
-- +===================================================================+
    PROCEDURE twe_pos_prc IS

    ln_posting_ctrl_id    NUMBER;
    lc_sob_ids            VARCHAR2(4000) := '';
    lc_batch_source_ids   VARCHAR2(100)  :='';
    lc_cycle_date         DATE;                                    -- DEFECT 30267
    
	--Defect - 28579 # added hint index_ffs
  --V1.8, Below suggested by Oracle 
   /*  If you think the query will start with a reasonable no. of rows you 
   could remove index_ffs hint - an INDEX RANGE SCAN will take place.
   Needed hints in this case: USE_NL(RCTLGD RCT XREF OOH GCC OOL XOHA XOLA HAOU HLA OPA)
   Previous Hint:   USE_NL(RCTLGD RCT GCC OOH OOL XOHA XOLA HAOU HLA OPA)
      index_ffs(XREF XX_AR_POS_INV_ORDER_REF_N3)   */  --V1.8

    lc_pos_trx            VARCHAR2(32767):=
--    'SELECT /*+ USE_NL(RCTLGD RCT XREF OOH GCC OOL XOHA XOLA HAOU HLA OPA) */    --COMMENTED BY ROHIT NANDA ON 21-AUG-2017 DEFECT# 43065 and replaced with parallel hint in next line
    'SELECT /*+ parallel(8) leading(RCTLGD) dynamic_sampling(0) */
           NVL(SUBSTR(HAOU.name,2,5),0)                              POS_LOCATION
            ,TO_CHAR(RCT.trx_date,''RRRRMMDD'')                      POS_SALE_DATE
            ,SUM((NVL(DECODE(OOL.line_category_code
                             ,''ORDER'',OOL.tax_value
                             ,''RETURN'', -1 * OOL.tax_value),0)))   POS_TAX_AMOUNT
            ,sum((NVL(DECODE(ool.TAX_EXEMPT_FLAG,''E'',0,DECODE(NVL(XOLA.taxable_flag,''Y'')
                             ,''Y'',OOL.unit_list_price
                                  * OOL.invoiced_quantity)),0)))    POS_TAXABLE_AMOUNT
            ,sum((NVL(DECODE(ool.TAX_EXEMPT_FLAG,''E'',0,DECODE(NVL(XOLA.taxable_flag,''Y'')
                            ,''N'',OOL.unit_list_price
                                 * OOL.invoiced_quantity)),0)))     POS_NON_TAXABLE_AMOUNT
            ,SUM(NVL(DECODE(OOL.TAX_EXEMPT_FLAG,''E'',
                                    OOL.unit_list_price
                                      * OOL.invoiced_quantity,0),0)) POS_TAX_EXEMPT_AMOUNT
            ,SUM((SELECT SUM(NVL(DECODE(OOL1.line_category_code
                                       ,''ORDER'',OPA1.operand*-1
                                       ,OPA1.operand),0))
                  FROM oe_order_lines_all    OOL1
                       ,oe_price_adjustments OPA1
                  WHERE OOL1.line_id = OPA1.line_id(+)
                  AND list_line_type_code(+)=''DIS''
                  AND OOL1.line_id=OOL.line_id))                     POS_DISCOUNT_AMOUNT
            ,GCC.segment1                                            POS_COMPANY
     FROM   oe_order_sources              OOS
            ,ra_cust_trx_line_gl_dist_all RCTLGD
            ,ra_customer_trx_all          RCT
            ,gl_code_combinations         GCC
            ,oe_order_headers_all         OOH
            ,oe_order_lines_all           OOL
            ,xx_om_header_attributes_all  XOHA
            ,xx_om_line_attributes_all    XOLA
            ,hr_all_organization_units    HAOU
            ,hr_locations_all             HLA
            ,xx_ar_pos_inv_order_ref     XREF                    --- Sinon SDR project
     WHERE  RCTLGD.account_class = ''REC''
     AND    RCTLGD.posting_control_id > #     -- # to be replaced at run time 
     AND    RCTLGD.latest_rec_flag = ''Y''
     AND    RCTLGD.set_of_books_id IN (~)     -- ~ to be replaced at run time
     AND    RCTLGD.code_combination_id = GCC.code_combination_id
     AND    RCTLGD.customer_trx_id = RCT.customer_trx_id
	   AND    RCT.batch_source_id in (!)        -- ! to be replaced at run time    
     --AND    RCT.attribute14 = OOH.header_id                          -- Sinon SDR Project
     AND    RCT.Customer_Trx_Id = XREF.Customer_Trx_id                 -- Sinon SDR Project
     AND    XREF.oe_Header_id = OOH.header_id                          -- Sinon SDR Project
     AND    OOH.order_source_id = OOS.order_source_id
     --AND    OOS.name IN(''POE'',''SPC'',''PRO'')                     -- Sinon Single Payment
     AND    OOS.name in (''POE'')                                         -- Sinon Single Payment
     AND    HAOU.location_id = HLA.location_id
     AND    OOH.ship_from_org_id = HAOU.organization_id
     AND    HLA.attribute14 IS NULL
     AND    OOH.header_id = XOHA.header_id
     AND    OOH.header_id = OOL.header_id
     AND    OOL.line_id = XOLA.line_id
     AND    RCTLGD.gl_date <= to_date(''&'')                           -- DEFECT 30267
     GROUP BY NVL(SUBSTR(HAOU.name,2,5),0)
              ,RCT.trx_date
              ,GCC.segment1';

    TYPE c_trx_rec_type IS RECORD(
                                   POS_LOCATION            hr_all_organization_units.name%TYPE
                                  ,POS_SALE_DATE           VARCHAR2(10)
                                  ,POS_TAX_AMOUNT          oe_order_lines_all.tax_value%TYPE
                                  ,POS_TAXABLE_AMOUNT      NUMBER
                                  ,POS_NON_TAXABLE_AMOUNT  NUMBER
                                  ,POS_TAX_EXEMPT_AMOUNT   xx_om_header_attributes_all.tax_exempt_amount%TYPE
                                  ,POS_DISCOUNT_AMOUNT     oe_price_adjustments.operand%TYPE
                                  ,POS_COMPANY             gl_code_combinations.segment1%TYPE
                                 );
    lr_trx_rec_type     c_trx_rec_type;

    BEGIN
      IF (p_debug = 'Y') THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'POS Procedure started');
      END IF;

      --Get last posting control id
      SELECT TO_NUMBER(NVL(XFTV.target_value1,'0'))
      INTO   ln_posting_ctrl_id
      FROM   xx_fin_translatedefinition XFTD
             ,xx_fin_translatevalues XFTV
      WHERE  XFTD.translate_id = XFTV.translate_id
      AND    XFTD.translation_name = 'AR_SALESTAX_DETAILS'
      AND    XFTV.source_value1 = 'POS_POSTING_CONTROL_ID'
      AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
      AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
      AND    XFTV.enabled_flag = 'Y'
      AND    XFTD.enabled_flag = 'Y';

     SELECT TRUNC(TO_DATE(p_cycle_date,'YYYY/MM/DD HH24:MI:SS'))                 -- DEFECT 30267
     INTO   lc_cycle_date
     FROM DUAL;

     SELECT MAX(posting_control_id)                                              -- DEFECT 30267
     into   LC_POS_ID
     FROM   ra_cust_trx_line_gl_dist_all
     WHERE  gl_date = lc_cycle_date;
	 
	 IF lc_pos_id > ln_posting_ctrl_id THEN --added for defect#38309

      UPDATE (SELECT XFTV.target_value1
              FROM   xx_fin_translatevalues XFTV
                    ,xx_fin_translatedefinition XFTD
              WHERE  XFTV.source_value1 = 'POS_POSTING_CONTROL_ID'
              AND    XFTD.translate_id = XFTV.translate_id
              AND    XFTD.translation_name = 'AR_SALESTAX_DETAILS')
      SET target_value1 = lc_pos_id;

      --IF (p_debug = 'Y') THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Posting control ID from previous run   : '||ln_posting_ctrl_id);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Updated Posting control ID             : '||lc_pos_id);
      --END IF;
	 ELSE	--added for defect#38309
    FND_FILE.PUT_LINE(FND_FILE.log,'Posting control ID from previous run   : '||LN_POSTING_CTRL_ID);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Since Posting control ID is '||lc_pos_id ||' so Translation Value remains unchanged');
     END IF;

      --Replacing with dynamic values
      lc_pos_trx := REPLACE(lc_pos_trx,'#',ln_posting_ctrl_id);
      lc_pos_trx := REPLACE(lc_pos_trx,'~',gc_sob_ids);
      lc_pos_trx := REPLACE(lc_pos_trx,'!',gc_batch_source_ids);
      lc_pos_trx := REPLACE(lc_pos_trx,'&',lc_cycle_date);


      --To fetch the mode to open file
      twe_utl_file(p_order_type,lc_file_mode);

      OPEN trx_ref_type FOR lc_pos_trx;
      LOOP
         FETCH trx_ref_type INTO lr_trx_rec_type;
         EXIT WHEN trx_ref_type%NOTFOUND;

         IF (p_debug = 'Y') THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Processing current POS record ');
         END IF;

         IF lc_file_open = 'N' THEN
          BEGIN
             gt_file := UTL_FILE.fopen(p_file_path, gc_file_name,lc_file_mode,ln_buffer);
          EXCEPTION
          WHEN UTL_FILE.INVALID_OPERATION THEN
             --Ensure that a file is created when trying to append a non-existent file
             gt_file := UTL_FILE.fopen(p_file_path, gc_file_name,'w',ln_buffer);
          END;
          lc_file_open := 'Y';
            IF (p_debug = 'Y') THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG,gc_file_name||' file has been opened');
            END IF;
         END IF;

         IF (lr_trx_rec_type.POS_TAX_AMOUNT < 0) THEN
          lc_tax_amt_sign := '-';
          ln_sum_tax_amt := ROUND(lr_trx_rec_type.POS_TAX_AMOUNT,2) * -100;
         ELSE
          lc_tax_amt_sign := '+';
          ln_sum_tax_amt := ROUND(lr_trx_rec_type.POS_TAX_AMOUNT,2) * 100;
         END IF;

         IF (lr_trx_rec_type.POS_TAXABLE_AMOUNT < 0) THEN
           lc_taxable_amt_sign := '-';
           ln_sum_taxable_amt := ROUND(lr_trx_rec_type.POS_TAXABLE_AMOUNT,2) * -100;
         ELSE
           lc_taxable_amt_sign := '+';
           ln_sum_taxable_amt := ROUND(lr_trx_rec_type.POS_TAXABLE_AMOUNT,2) * 100;
         END IF;

         IF (lr_trx_rec_type.POS_NON_TAXABLE_AMOUNT < 0) THEN
           lc_non_taxable_amt_sign := '-';
           ln_sum_non_taxable_amt := ROUND(lr_trx_rec_type.POS_NON_TAXABLE_AMOUNT,2) * -100;
         ELSE
           lc_non_taxable_amt_sign := '+';
           ln_sum_non_taxable_amt := ROUND(lr_trx_rec_type.POS_NON_TAXABLE_AMOUNT,2) * 100;
         END IF;


         IF (lr_trx_rec_type.POS_TAX_EXEMPT_AMOUNT < 0) THEN
           lc_tax_exempt_amt_sign := '-';
           ln_sum_tax_exempt_amt := ROUND(lr_trx_rec_type.POS_TAX_EXEMPT_AMOUNT,2) * -100;
         ELSE
           lc_tax_exempt_amt_sign := '+';
           ln_sum_tax_exempt_amt := ROUND(lr_trx_rec_type.POS_TAX_EXEMPT_AMOUNT,2) * 100;
         END IF;

         IF (lr_trx_rec_type.POS_DISCOUNT_AMOUNT < 0) THEN
           lc_disc_amt_sign := '-';
           ln_sum_disc_amt := ROUND(lr_trx_rec_type.POS_DISCOUNT_AMOUNT,2) * -100;
         ELSE
           lc_disc_amt_sign := '+';
           ln_sum_disc_amt := ROUND(lr_trx_rec_type.POS_DISCOUNT_AMOUNT,2) * 100;
         END IF;

         lc_comp := lr_trx_rec_type.POS_COMPANY;

         IF ( lc_comp = lc_pre_comp) THEN
              NULL;
         ELSE
              SELECT XFTV.source_value1
              INTO lc_company
              FROM xx_fin_translatedefinition XFT
                   ,xx_fin_translatevalues XFTV
              WHERE XFT.translation_name='GL_PSFIN_COMPANY'
              AND XFTV.target_value1 = lr_trx_rec_type.POS_COMPANY
              AND XFTV.translate_id = XFT.translate_id
              AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
              AND SYSDATE BETWEEN XFT.start_date_active AND NVL(XFT.end_date_active,SYSDATE+1)
              AND XFTV.enabled_flag = 'Y'
              AND XFT.enabled_flag = 'Y'
              AND ROWNUM<2;
              IF (p_debug = 'Y') THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'New PSFIN company value derived from translation');
              END IF;
              lc_pre_comp := lr_trx_rec_type.POS_COMPANY;
         END IF;

         lc_filedata:=(LPAD(lr_trx_rec_type.POS_LOCATION,5,0) ||
                       LPAD(lr_trx_rec_type.POS_SALE_DATE,8,0)||
                       lc_tax_amt_sign||
                      LPAD(ln_sum_tax_amt,11,0)||
                      lc_taxable_amt_sign||
                      LPAD(ln_sum_taxable_amt,11,0)||
                      lc_non_taxable_amt_sign||
                      LPAD(ln_sum_non_taxable_amt,11,0)||
                      lc_tax_exempt_amt_sign||
                      LPAD(ln_sum_tax_exempt_amt,11,0)||
                      lc_disc_amt_sign||
                      LPAD(ln_sum_disc_amt,11,0)||
                      LPAD(lc_company,5,0)
                      );
         IF (p_debug = 'Y') THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Current record to be written to Vertex File is :');
            FND_FILE.PUT_LINE(FND_FILE.LOG,lc_filedata);
         END IF;
         lc_record_exist := 'Y';
        UTL_FILE.PUT_LINE(gt_file , lc_filedata);
        lc_filedata := NULL;
        lc_comp     := NULL;
      END LOOP;

      --To close the file
      IF lc_file_open = 'Y' THEN
           UTL_FILE.fclose(gt_file);
      END IF;

    EXCEPTION
    WHEN OTHERS THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised in POS procedure : '
                           || SQLERRM);
    END;


-- +===================================================================+
-- | Name       : TWE_AOPS_PRC                                         |
-- +===================================================================+

   PROCEDURE twe_aops_prc IS
   ln_posting_ctrl_id    NUMBER;
   lc_sob_ids            VARCHAR2(4000) := '';
   lc_batch_source_ids   VARCHAR2(100)  := '';
   lc_cycle_date         DATE           ;                                       -- DEFECT 30267
   lc_aops_trx           VARCHAR2(32767)
   :=
--   'SELECT /*+ USE_NL(RCTLGD RCT HZ GCC OOH OOL XOHA XOLA HAOU HLA OPA) */--COMMENTED BY ROHIT NANDA ON 21-AUG-2017 DEFECT# 43065 and replaced with parallel hint in next line
    'SELECT /*+ parallel(8) leading(RCTLGD) dynamic_sampling(0) */
               NVL(SUBSTR(RCT.trx_number,1,(LENGTH(RCT.trx_number)-3)),0)                                     AOPS_ORDER_NBR
               ,NVL(SUBSTR(RCT.trx_number,(LENGTH(RCT.trx_number)-2),LENGTH(RCT.trx_number)),0)               AOPS_ORDER_SUB_NBR
               ,TO_CHAR(RCT.trx_date,''RRRRMMDD'')                                                            AOPS_SALE_DATE
               ,''099''                                                                                       AOPS_REG_NBR
               ,NVL(substr(XOHA.tran_number,-5),0)                                                            AOPS_TRAN_NUMBER
               ,NVL(SUBSTR(HAOU.name,2,5),0)                                                                  AOPS_SHIP_FROM_LOC
               ,NVL(SUBSTR(HAOU_ALT.name,2,5),0)                                                              AOPS_ALTERNATE_LOC
               ,NVL(XOHA.aops_geo_code,0)                                                                     AOPS_GEO_DEST_CODE
               ,NVL(SUBSTR(HZ.orig_system_reference, 1 , INSTR(HZ.orig_system_reference,''-'')-1),0)          AOPS_CUSTOMER_NBR
               ,SUM(NVL((DECODE(OOL.line_category_code
                                ,''ORDER'',OOL.tax_value
                                ,''RETURN'', -1 * OOL.tax_value ) ),0))                                       AOPS_TAX_AMOUNT
               ,SUM(NVL(DECODE(OOL.TAX_EXEMPT_FLAG,''E'',
                                    OOL.unit_list_price
                                      * OOL.invoiced_quantity,0),0))                                          AOPS_TAX_EXEMPT_AMOUNT
               ,SUM(NVL(DECODE(OOL.TAX_EXEMPT_FLAG,''E'',0,(OOL.unit_list_price * OOL.invoiced_quantity)),0))                                     AOPS_SUBTOTAL_AMOUNT
               ,SUM((SELECT SUM(NVL(DECODE(OOL1.line_category_code
                                           ,''ORDER'',OPA1.operand*-1
                                           ,OPA1.operand),0))
                     FROM oe_order_lines_all    OOL1
                          ,oe_price_adjustments OPA1
                     WHERE OOL1.line_id = OPA1.line_id(+)
                     AND list_line_type_code(+)=''DIS''
                     AND OOL1.line_id=OOL.line_id))                                                           AOPS_DISCOUNT_AMOUNT
               ,GCC.segment1                                                                                  AOPS_COMPANY
     FROM ra_cust_trx_line_gl_dist_all RCTLGD
          ,ra_customer_trx_all RCT
          ,hz_cust_accounts HZ
          ,oe_order_headers_all OOH
          ,oe_order_sources OOS
          ,hr_all_organization_units HAOU
          ,hr_all_organization_units HAOU_ALT
          ,xx_om_header_attributes_all XOHA
          ,oe_order_lines_all OOL
          ,gl_code_combinations GCC
     WHERE 1=1
     AND RCTLGD.account_class =''REC''
     AND RCTLGD.latest_rec_flag = ''Y''
     AND RCTLGD.posting_control_id > #  -- # to be replaced at run time
     AND RCTLGD.customer_trx_id = RCT.customer_trx_id
	  AND RCT.batch_source_id in (!)     -- ! to be replaced at run time
     AND RCTLGD.set_of_books_id IN (~)  -- ~ to be replaced at run time
     AND RCTLGD.code_combination_id = GCC.code_combination_id
     AND RCT.bill_to_customer_id = HZ.cust_account_id
     AND RCT.attribute14 = OOH.header_id
     AND OOH.order_source_id = OOS.order_source_id
     --AND OOS.name NOT IN (''POE'',''SPC'',''PRO'')                        --- Sinon SDR/Single payment Project
     --AND OOS.name IN ("SPC","PRO")     ---,”**Single Payment”)                        --- Sinon SDR/Single payment Project
     --AND OOS.name <> ''POE''
     AND OOH.ship_from_org_id = HAOU.organization_id
     AND OOH.header_id = XOHA.header_id
     AND XOHA.paid_at_store_id = HAOU_ALT.organization_id(+)
     AND OOH.header_id = OOL.header_id
     and (OOS.name <> ''POE'' 
          or (OOS.name = ''POE'' AND rct.interface_Header_context = ''ORDER ENTRY'')) -- defect 17016  this will pickup the single payment POS trans.
     AND RCTLGD.gl_date <= to_date(''&'')                                          -- DEFECT 30267
     GROUP BY RCT.trx_number
              ,RCT.trx_date
              ,''099''
              ,XOHA.tran_number
              ,HAOU.name
              ,HAOU_ALT.name
              ,XOHA.aops_geo_code
              ,HZ.orig_system_reference
              ,GCC.segment1';

    TYPE c_trx_rec_type IS RECORD(
                                   AOPS_ORDER_NBR           ra_customer_trx_all.trx_number%TYPE
                                  ,AOPS_ORDER_SUB_NBR       ra_customer_trx_all.trx_number%TYPE
                                  ,AOPS_SALE_DATE           VARCHAR2(10)
                                  ,AOPS_REG_NBR             VARCHAR2(5)
                                  ,AOPS_TRAN_NUMBER         xx_om_header_attributes_all.tran_number%TYPE
                                  ,AOPS_SHIP_FROM_LOC       hr_all_organization_units.name%TYPE
                                  ,AOPS_ALTERNATE_LOC       hr_all_organization_units.name%TYPE
                                  ,AOPS_GEO_DEST_CODE       xx_om_header_attributes_all.aops_geo_code%TYPE
                                  ,AOPS_CUSTOMER_NBR        hz_cust_accounts.orig_system_reference%TYPE
                                  ,AOPS_TAX_AMOUNT          oe_order_lines_all.tax_value%TYPE
                                  ,AOPS_TAX_EXEMPT_AMOUNT   xx_om_header_attributes_all.tax_exempt_amount%TYPE
                                  ,AOPS_SUBTOTAL_AMOUNT     NUMBER
                                  ,AOPS_DISCOUNT_AMOUNT     oe_price_adjustments.operand%TYPE
                                  ,AOPS_COMPANY             gl_code_combinations.segment1%TYPE
                                 );
    lr_trx_rec_type     c_trx_rec_type;

    BEGIN
      IF (p_debug = 'Y') THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'AOPS Procedure started');
      END IF;

      --Get last posting control id
      SELECT TO_NUMBER(NVL(XFTV.target_value1,'0'))
      INTO   ln_posting_ctrl_id
      FROM   xx_fin_translatedefinition XFTD
             ,xx_fin_translatevalues XFTV
      WHERE  XFTD.translate_id = XFTV.translate_id
      AND    XFTD.translation_name = 'AR_SALESTAX_DETAILS'
      AND    XFTV.source_value1 = 'AOPS_POSTING_CONTROL_ID'
      AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
      AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
      AND    XFTV.enabled_flag = 'Y'
      AND    XFTD.enabled_flag = 'Y';

     SELECT TRUNC(TO_DATE(p_cycle_date,'YYYY/MM/DD HH24:MI:SS'))                     -- DEFECT 30267 
     INTO   lc_cycle_date
     FROM DUAL;

     SELECT MAX(posting_control_id)                                                  -- DEFECT 30267
     into   LC_POS_ID
     FROM   ra_cust_trx_line_gl_dist_all
     WHERE  gl_date = lc_cycle_date;
	 
	 IF lc_pos_id > ln_posting_ctrl_id THEN	--added for defect#38309

      UPDATE (SELECT XFTV.target_value1
              FROM   xx_fin_translatevalues XFTV
                     ,xx_fin_translatedefinition XFTD
              WHERE  XFTV.source_value1 = 'AOPS_POSTING_CONTROL_ID'
              AND    XFTD.translate_id = XFTV.translate_id
              AND    XFTD.translation_name = 'AR_SALESTAX_DETAILS')
			  
      SET target_value1 = lc_pos_id;

      --IF (p_debug = 'Y') THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Posting control ID from previous run   : '||ln_posting_ctrl_id);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Updated Posting control ID             : '||lc_pos_id);
      --END IF;
	 ELSE  	--added for defect#38309
    FND_FILE.PUT_LINE(FND_FILE.log,'Posting control ID from previous run   : '||LN_POSTING_CTRL_ID);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Since Posting control ID is '||lc_pos_id || ' so Translation Value remains unchanged');
	  
     END IF;

      --Replacing with dynamic values
      lc_aops_trx := REPLACE(lc_aops_trx,'#',ln_posting_ctrl_id);
      lc_aops_trx := REPLACE(lc_aops_trx,'~',gc_sob_ids);
      lc_aops_trx := REPLACE(lc_aops_trx,'!',gc_batch_source_ids);
      lc_aops_trx := REPLACE(lc_aops_trx,'&',lc_cycle_date);

      --To fetch the mode to open file
      twe_utl_file(p_order_type,lc_file_mode);

      OPEN trx_ref_type FOR lc_aops_trx;
      LOOP
         FETCH trx_ref_type INTO lr_trx_rec_type;
         EXIT WHEN trx_ref_type%NOTFOUND;

         IF (p_debug = 'Y') THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Processing current AOPS record ');
         END IF;

         IF lc_file_open = 'N' THEN
            BEGIN
               gt_file := UTL_FILE.fopen(p_file_path, gc_file_name,lc_file_mode,ln_buffer);
            EXCEPTION
            WHEN UTL_FILE.INVALID_OPERATION THEN
               --Ensure that a file is created when trying to append a non-existent file
               gt_file := UTL_FILE.fopen(p_file_path, gc_file_name,'w',ln_buffer);
            END;
            lc_file_open := 'Y';
            IF (p_debug = 'Y') THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG,gc_file_name||' file has been opened');
            END IF;
         END IF;

         IF (lr_trx_rec_type.AOPS_TAX_AMOUNT < 0) THEN
                lc_aops_tax_amt_sign := '-';
            ln_aops_tax_amt := ROUND(lr_trx_rec_type.AOPS_TAX_AMOUNT,2) * -100;
         ELSE
            lc_aops_tax_amt_sign := '+';
            ln_aops_tax_amt := ROUND(lr_trx_rec_type.AOPS_TAX_AMOUNT,2) * 100;

         END IF;

         IF (lr_trx_rec_type.AOPS_SUBTOTAL_AMOUNT < 0) THEN
           lc_aops_subtot_amt_sign := '-';
           ln_aops_subtot_amt := ROUND(lr_trx_rec_type.AOPS_SUBTOTAL_AMOUNT,2) * -100;
         ELSE
           lc_aops_subtot_amt_sign := '+';
           ln_aops_subtot_amt := ROUND(lr_trx_rec_type.AOPS_SUBTOTAL_AMOUNT,2) * 100;
         END IF;

         IF (lr_trx_rec_type.AOPS_TAX_EXEMPT_AMOUNT < 0) THEN
           lc_aops_tax_exe_amt_sign := '-';
           ln_aops_tax_exe_amt := ROUND(lr_trx_rec_type.AOPS_TAX_EXEMPT_AMOUNT,2) * -100;
         ELSE
           lc_aops_tax_exe_amt_sign := '+';
           ln_aops_tax_exe_amt := ROUND(lr_trx_rec_type.AOPS_TAX_EXEMPT_AMOUNT,2) * 100;

         END IF;

         IF (lr_trx_rec_type.AOPS_DISCOUNT_AMOUNT < 0) THEN
           lc_aops_disc_amt_sign := '-';
           ln_aops_disc_amt := ROUND(lr_trx_rec_type.AOPS_DISCOUNT_AMOUNT,2) * -100;
         ELSE
           lc_aops_disc_amt_sign := '+';
           ln_aops_disc_amt := ROUND(lr_trx_rec_type.AOPS_DISCOUNT_AMOUNT,2) * 100;
         END IF;

         lc_comp := lr_trx_rec_type.AOPS_COMPANY;

         IF ( lc_comp = lc_pre_comp) THEN
              NULL;
         ELSE
              SELECT XFTV.source_value1
              INTO lc_company
              FROM xx_fin_translatedefinition XFT
                   ,xx_fin_translatevalues XFTV
              WHERE XFT.translation_name='GL_PSFIN_COMPANY'
              AND XFTV.target_value1 = lr_trx_rec_type.AOPS_COMPANY
              AND XFTV.translate_id = XFT.translate_id
              AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
              AND SYSDATE BETWEEN XFT.start_date_active AND NVL(XFT.end_date_active,SYSDATE+1)
              AND XFTV.enabled_flag = 'Y'
              AND XFT.enabled_flag = 'Y'
              AND ROWNUM<2;
              lc_pre_comp := lr_trx_rec_type.AOPS_COMPANY;
              IF (p_debug = 'Y') THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'New PSFIN company value derived from translation');
              END IF;
         END IF;

	      lc_filedata := (LPAD(lr_trx_rec_type.AOPS_ORDER_NBR,9,0)||
                         LPAD(lr_trx_rec_type.AOPS_ORDER_SUB_NBR,3,0)||
                         LPAD(lr_trx_rec_type.AOPS_SALE_DATE,8,0)||
                         LPAD(lr_trx_rec_type.AOPS_REG_NBR,3,0)||
                         LPAD(lr_trx_rec_type.AOPS_TRAN_NUMBER,5,0)||
                         LPAD(lr_trx_rec_type.AOPS_SHIP_FROM_LOC,5,0)||
                         LPAD(lr_trx_rec_type.AOPS_ALTERNATE_LOC,5,0)||
                         LPAD(lr_trx_rec_type.AOPS_GEO_DEST_CODE,9,0)||
                         LPAD(lr_trx_rec_type.AOPS_CUSTOMER_NBR,9,0)||
                         lc_aops_tax_amt_sign||
                         LPAD(ln_aops_tax_amt,11,0)||
                         lc_aops_tax_exe_amt_sign||
                         LPAD(ln_aops_tax_exe_amt,11,0)||
                         lc_aops_subtot_amt_sign||
                         LPAD(ln_aops_subtot_amt,11,0)||
                         lc_aops_disc_amt_sign||
                         LPAD(ln_aops_disc_amt,11,0)||
                         LPAD(lc_company,5,0)
                         );
         IF (p_debug = 'Y') THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Current record to be written to Vertex File is :');
            FND_FILE.PUT_LINE(FND_FILE.LOG,lc_filedata);
         END IF;
          --To write data to the file
          UTL_FILE.PUT_LINE(gt_file , lc_filedata);
          lc_record_exist := 'Y';
          lc_filedata := NULL;
          lc_comp     := NULL;

      END LOOP;
              --To close the file
      IF lc_file_open = 'Y' THEN
           UTL_FILE.fclose(gt_file);
      END IF;

   EXCEPTION
          WHEN OTHERS THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised in AOPS procedure : '
                          || SQLERRM);
   END;

-- +===================================================================+
-- |   main procedure                                                  |
-- +===================================================================+
   BEGIN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'*********************************************************************************************');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Parameters passed are:');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'p_order_type      :  '||p_order_type    );
        FND_FILE.PUT_LINE(FND_FILE.LOG,'p_file_path       :  '||p_file_path     );
        FND_FILE.PUT_LINE(FND_FILE.LOG,'p_cycle_date      :  '||p_cycle_date    );
        FND_FILE.PUT_LINE(FND_FILE.LOG,'*********************************************************************************************');
        --To get the source file path
        BEGIN
                SELECT directory_path
                INTO   lc_source_file_path
                FROM   dba_directories
                WHERE  directory_name = p_file_path;

        EXCEPTION
                WHEN OTHERS THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching the Source File Path : '
                                                || SQLERRM);
        END;

        IF (p_debug = 'Y') THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Source File Path derived is            : '||lc_source_file_path);
        END IF;

		  -----Getting the SOB and Batch Source ID's
		  FOR c_sob_id IN (
                       SELECT GSOB.set_of_books_id
                       FROM   gl_sets_of_books GSOB
                              ,xx_fin_translatedefinition XFTD
                              ,xx_fin_translatevalues XFTV
                       WHERE  XFTD.translate_id = XFTV.translate_id
                       AND    XFTD.translation_name = 'GL_DEFAULT_VALUES'
                       AND    XFTV.target_value1 = GSOB.short_name
                       AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                       AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                       AND    XFTV.enabled_flag = 'Y'
                       AND    XFTD.enabled_flag = 'Y'
                       )
      LOOP

         gc_sob_ids := gc_sob_ids || c_sob_id.set_of_books_id || ',';
      END LOOP;

		FOR c_batch_source_id IN (
		                          SELECT rbs.batch_source_id
											FROM fnd_lookup_values flv,
												  ra_batch_sources_all rbs
											WHERE flv.lookup_code = rbs.name
											AND lookup_type = 'TWE_RECORD_SOURCES'
											AND enabled_flag ='Y'
											AND trunc(sysdate) between flv.start_date_active and nvl(flv.end_date_active,sysdate)
											AND nvl(rbs.status,'X')='A'
										)
		LOOP
			gc_batch_source_ids := gc_batch_source_ids||c_batch_source_id.batch_source_id||',';
		END LOOP;

      gc_sob_ids := SUBSTR(gc_sob_ids,1,LENGTH(gc_sob_ids)-1);
		gc_batch_source_ids := SUBSTR(gc_batch_source_ids,1,LENGTH(gc_batch_source_ids)-1);


      FND_FILE.PUT_LINE(FND_FILE.LOG,'SOB IDs dervied from GL_DEFAULT_VALUES : '||gc_sob_ids);
		FND_FILE.PUT_LINE(FND_FILE.LOG,'Batch Source ID from TWE_RECORD_SOURCES: '||gc_batch_source_ids);

        IF (p_order_type ='POS') THEN
                --Call the POS procedure
                twe_pos_prc;
        ELSE
                --Call the AOPS procedure
                twe_aops_prc;
        END IF;

        COMMIT;

        FND_FILE.PUT_LINE(FND_FILE.LOG,'                                       Extract Complete');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'*********************************************************************************************');

   --Query to fetch the last day of week

   SELECT XFTV.target_value1
        INTO lc_last_day
        FROM   xx_fin_translatedefinition XFTD
               ,xx_fin_translatevalues XFTV
        WHERE  XFTD.translate_id = XFTV.translate_id
        AND    XFTD.translation_name = 'AR_SALESTAX_DETAILS'
        AND    XFTV.source_value1 = 'LAST_DAY'
        AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
        AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
        AND    XFTV.enabled_flag = 'Y'
        AND    XFTD.enabled_flag = 'Y';

   IF (lc_cycle_day = lc_last_day) THEN
      lc_last_day_flag := 'Y';
   END IF;

        -------------- Call the Common file copy Program --------------

        IF lc_last_day_flag = 'Y' THEN
           lc_source_file_name  :=  lc_source_file_path || '/' || gc_file_name;
           --lc_dest_file_name    :=  p_dest_file_path||'/'|| gc_file_name;
           /*ln_req_id := FND_REQUEST.SUBMIT_REQUEST (application    => 'XXFIN'
                                                    ,PROGRAM       => 'XXCOMFILCOPY'
                                                    ,description   => ''
                                                    ,sub_request   => FALSE
                                                    ,argument1     => lc_source_file_name
                                                    ,argument2     => lc_dest_file_name
                                                    ,argument3     => NULL
                                                    ,argument4     => NULL
                                                    ,argument5     => 'Y'
                                                    ,argument6     => '$XXFIN_DATA/archive/inbound'
                                                   );*/
           IF (lc_record_exist = 'N' AND lc_file_mode = 'w') THEN
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'*********************************************************************************************');
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                     No Data Found');
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'*********************************************************************************************');
           ELSE

              IF (p_order_type = 'POS') THEN
                 lc_dest_file_name := gc_pos_dest_file;
              ELSE
                 lc_dest_file_name := gc_aops_dest_file;
              END IF;

              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Source file  Path     : ' || lc_source_file_name);
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The File Copied  Path     : ' || lc_dest_file_name);

              ln_req_id := FND_REQUEST.SUBMIT_REQUEST (application    => 'XXFIN'
                                                       ,PROGRAM       => 'XXCOMFTP'
                                                       ,description   => ''
                                                       ,sub_request   => FALSE                 --defect 14240
                                                       ,argument1     => 'OD_AR_VERTEX_IFACE'
                                                       ,argument2     => gc_file_name
                                                       ,argument3     => lc_dest_file_name
                                                       ,argument4     => 'Y'
                                                      );
              COMMIT;

              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The OD: Common Put Program is submitted '
                                                 || ' Request id : ' || ln_req_id);

              IF (ln_req_id <> 0) THEN
                 lb_req_status := FND_CONCURRENT.WAIT_FOR_REQUEST(
                                                  request_id   => ln_req_id
                                                  ,interval    => ln_max_wait_int
                                                  ,max_wait    => NULL
                                                  ,phase       => lc_phase
                                                  ,status      => lc_status
                                                  ,dev_phase   => lc_devphase
                                                  ,dev_status  => lc_devstatus
                                                  ,message     => lc_message
                                                 );
              END IF;


              FND_FILE.PUT_LINE(FND_FILE.LOG,'FTP Program Phase: '|| lc_devphase ||' Status: '|| lc_devstatus);

              IF (lc_devphase = 'COMPLETE' AND lc_devstatus = 'ERROR') THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Error occured in FTP program');
                 x_ret_code   := 2;
                 x_error_buff := 'Error occured in FTP program';
              END IF;
           END IF;
        ELSE
           IF (lc_record_exist = 'N') THEN
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'*********************************************************************************************');
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                     No Data Found');
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'*********************************************************************************************');
           END IF;
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Cycle run day '||lc_cycle_day||' is not '||lc_last_day||'. File not put to Vertex folder');
        END IF;

   EXCEPTION
   WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while Submitting the OD: Common Put Program : '
                                                || SQLERRM);
   END;

END XX_SALES_TAX_REPORT_PKG;
/
SHOW ERROR
