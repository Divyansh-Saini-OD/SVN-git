SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET TERM ON
PROMPT Creating PACKAGE Body XX_GL_COGS_INT_MASTER_PKG
PROMPT Program exits IF the creation is not successful
WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_GL_COGS_INT_MASTER_PKG
AS
-- +===================================================================+-----Modified for CR 661 for RICE I2119
-- |                  Office Depot - Project Simplify                  |
-- |                    Office Depot Organization                      |
-- +===================================================================+
-- | Name  : XX_GL_COGS_INT_MASTER_PKG                                 |
-- | Description :  This PKG will be used to interface COGS            |
-- |                 data with the Oracle GL                           |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A DD-MON-YYYY  P.Marco          Initial draft version       |
-- |1.0      25-JUN-2007  P.Marco                                      |
-- |1.1      23-OCT-2007  P.Marco          Added decode statement to   |
-- |                                       handle credit transactions  |
-- |                                       IF quantity_invoice is null |
-- |                                       use quantity_credited in    |
-- |                                       amount formula              |
-- |                                                                   |
-- |1.2      24-OCT-2007  Arul Justin Raj  Fixed Defect for 2436       |
-- |                                       When build the Journal Line |
-- |                                       to get Consignment Account  |
-- |                                       from Attrbiute10 for        |
-- |                                       Consigment line             |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |1.3       19-DEc-2007                  Defect 3117  Default Account|
-- |                                       segment to 00000 on journal |
-- |                                       creation.                   |
-- |1.4       28-FEB-2008   Srividya S     Funtion Added as part of    |
-- |                                       Defect #3456 to fetch the   |
-- |                                       LOB values based on the     |
-- |                                       Location_Type and Fixed the |
-- |                                       defect #4903                |
-- |1.5       25-MAR-2008    Raji          Fixed defect # 5716         |
-- |          29-MAR-2008    Raji          Fixed defect # 5888         |
-- |1.6       10-MAY-2008    Prakash S     - Performance Fixes         |
-- |                                       - p_chk_bal_flag = 'N'      |
-- |1.7       14-MAY-2008    Raji          Performanc Fixes            |
-- |          16-MAY-2008    Raji          Fixed defect 7145           |
-- |1.8       06-JUNE-2008   Srividya      Fixed defect #7700          |
-- |          06-JUNE-2008   Srividya      Fixed defect #7684          |
 --|          06-JUNE-2008   Srinidhi      Fixed defect #7793          |
 --|                                       Populated few refrence      |
 --|                                       columns in staging table    |
 --|1.9       19-JUNE-2008  Raji           Fixed defect 8261           |
 --|2.0       20-JUNE-2008  Raji           Perf fixes for defect 8242  |
 --|          24-JUNE-2008  Raji           Fixed defect 8283           |
 --|          26-JUNE-2008  Raji           Fixed defect 8506           |
 --|2.1       07-JUNE-2008  Manovinayak    Added code for the defect   |
 --|                                            #8706 and #8705        |
 --|2.2       25-July-2008  Manovinayak    Fixed the defect for 9123   |
 --|2.3       10-AUG-08     Srividya       Changes for Defect 9696     |
 --|2.4       23-MAR-2009   Lincy K        Modified code for Defect    |
 --|2.5       16-MAR-2010   Priyanka N     Modified code for CR 661    |
 --|                                       for RICE ID I2119           |
 --|2.6       20-APR-2010   Priyanka N     Modified Code for           |
 --|                                       Defect 3098 CCID Fix        |
 --|2.7       27-APR-2010   Priyanka N     Modified Code for           |
 --|                                       Defect 3098  for Exception  |
 --|                                       Report Submission           |
 --| 2.8      21-JUL-10     Nilanjana      Modified UPDATE_COGS_FLAG   |
 --|                                       for Defect 5494 to prevent  |
 --|                                       deletion of NON COGS records|
 --| 2.9      11-MAR-11     GAURAV AGARWAL Modified the code for SDR   |
 --|                                       changes.                    |
-- | 3.0      18-NOV-2015   Madhu Bolli    Remove schema for 12.2 retrofit | 
-- +===================================================================+
-----GLOBAL VARIABLES-----
    gn_rec_cnt                    NUMBER := 0;
    gc_debug_flg                  VARCHAR2(1)  := 'N';
    gc_submit_exception_report    VARCHAR2(1)  := 'N';            ---Added for Defect 3098 on 27-Apr-10
-- +===================================================================+
-- | Name         :XX_DERIVE_LOB_TEST                                  |
-- | Description  :This Funtion will fetch the LOB values              |
-- |               corresponding to the location from the              |
-- |               translation 'XX_RA_COGS_LOB_VALUES'                 |
-- |                                                                   |
-- | Parameters   :Location                                            |
-- | Returns      :LOB                                                 |
-- +===================================================================+
    FUNCTION XX_DERIVE_LOB_TEST(p_location IN VARCHAR2)
    RETURN NUMBER
    IS
     ln_lob_type  xx_fin_translatevalues.target_value1%TYPE;
     lc_loc_type  fnd_flex_values_vl.attribute2%TYPE;
       BEGIN
---------------- To Fetch  location Lype ---------------
          BEGIN
               SELECT FFV.attribute2
               INTO   lc_loc_type
               FROM   fnd_flex_values FFV
                     ,fnd_flex_value_sets FFVS
               WHERE FFV.flex_value_set_id = FFVS.flex_value_set_id
               AND   FFVS.flex_value_set_name = 'OD_GL_GLOBAL_LOCATION'
               AND   FFV.flex_value = p_location;
         EXCEPTION
         WHEN OTHERS   THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching the location Type  :'  || SQLERRM );
         END;
---------------- To Fetch  LOB for the Specified location Lype ---------------
         BEGIN
               SELECT  XFT.target_value1
               INTO    ln_lob_type
               FROM    xx_fin_translatedefinition XFTD
                      ,xx_fin_translatevalues XFT
               WHERE   XFTD.translate_id = XFT.translate_id
               AND     XFTD.translation_name = 'XX_RA_COGS_LOB_VALUES'
               AND     XFT.enabled_flag = 'Y'
               AND     XFT.source_value1=lc_loc_type;
         EXCEPTION
         WHEN OTHERS   THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching the location LOB from Translation  :'  || SQLERRM );
         END;
     RETURN ln_lob_type;
     END XX_DERIVE_LOB_TEST;
-- +===================================================================+
-- | Name         : PROCESS_JOURNALS_CHILD                             |
-- | Description  : The main controlling procedure for the COGS        |
-- |                interfaces.It inserts data into the                |
-- |                XX_GL_INTERFACE_NA_STG Table                       |
-- |                                                                   |
-- |                                                                   |
-- | Parameters :p_source_name,p_debug_flg,p_debug_flg,p_batch_size    |
-- |             p_cust_trx_id_low,p_cust_trx_id_high,p_gl_date_low    |
-- |             p_otc_cycle_run_date,p_otc_cycle_wave_num             |
-- |                                                                   |
-- | Returns : x_return_code, x_return_message                         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE PROCESS_JOURNALS_CHILD (x_return_message          OUT VARCHAR2
                                     ,x_return_code             OUT VARCHAR2
                                     ,p_source_name             IN  VARCHAR2
                                     ,p_debug_flg               IN  VARCHAR2
                                     ,p_batch_size              IN  NUMBER
                                     ,p_cust_trx_id_low         IN  NUMBER
                                     ,p_cust_trx_id_high        IN  NUMBER
                                     ,p_gl_date_low             IN  VARCHAR2
                                     ,p_gl_date_high            IN  VARCHAR2
                                     ,p_otc_cycle_run_date      IN  VARCHAR2
                                     ,p_otc_cycle_wave_num      IN  NUMBER
                                     )
     IS
          NO_GROUP_ID_FOUND    EXCEPTION;
          ---------------------------
          -- local variables declared
          ---------------------------
          lc_debug_msg         VARCHAR2(2000);
          ln_user_id           xx_gl_interface_na_stg.created_by%TYPE;
          ln_group_id          xx_gl_interface_na_stg.group_id%TYPE;
          ln_set_of_books_id   NUMBER;
          lc_period_end        VARCHAR2(15);
          ln_conc_request_id   NUMBER:= FND_GLOBAL.CONC_REQUEST_ID();
          ln_parent_request_id NUMBER;
CURSOR c_insert_je_lines_test
IS
  SELECT
       'NEW'                                                                                        STATUS
       ,RAD.set_of_books_id                                                                         SOB
       ,RAD.gl_date                                                                                 ACCT_DATE
       ,GLS.currency_code                                                                           CURR_CODE
       ,SYSDATE                                                                                     DATE_CRTD
       ,ln_user_id                                                                                  CRTD_BY
       ,'A'                                                                                         ACT_FLG
      -- ,p_source_name                                                                               JE_CAT --Commented By GAGARWAL on 11-Mar-2011 for SDR Project

    ,      Decode (rctta.type,'INV','Sales Invoices','CM','Credit Memos','OD COGS')  JE_CAT --Added By GAGARWAL on 11-Mar-2011 for SDR Project

       ,p_source_name                                                                               JE_SRC
       ,DERIVE_COMPANY_FROM_LOCATION(DECODE(SIGN(RAL.revenue_amount)
                                      ,- 1,GLC.segment4
                                     ,DECODE(GLC.segment4
                                        ,NVL(SUBSTR(HOU.name,1,6),GLC.segment4),GLC.segment4
                                            ,NVL(SUBSTR(HOU.name,1,6),GLC.segment4)
                                            )
                                       )
                                                             )                                      SEGMENT1_CR
       ,DERIVE_COMPANY_FROM_LOCATION(DECODE(SIGN(RAL.revenue_amount)
                                          ,-1,DECODE(GLC.segment4
                                            ,NVL(SUBSTR(HOU.name,1,6),GLC.segment4),GLC.segment4
                                              ,SUBSTR(HOU.name,1,6)
                                                 )
                                                  ,GLC.segment4
                                           )
                                     )                                                              SEGMENT1_DR
       ,DECODE(SUBSTR(DECODE(SIGN(RAL.revenue_amount)
                            ,- 1,DECODE(TRIM(RAD.attribute10)
                                        , NULL,TRIM(RAD.attribute8)
                                        ,TRIM(RAD.attribute10)
                                        )
                            ,TRIM(RAD.attribute7)
                            )
                      ,1,1
                      )
              ,'1','00000'
              ,'2','00000'
              ,'3','00000'
              ,'4','00000'
              ,'5','00000'
              ,GLC.segment2
              )                                                                                     SEGMENT2_DR
       ,DECODE(SUBSTR(DECODE(SIGN(RAL.revenue_amount)
                            ,- 1,RAD.attribute7
                            ,DECODE(TRIM(RAD.attribute10)
                                   , NULL,TRIM(RAD.attribute8)
                                   ,TRIM(RAD.attribute10)
                                   )
                           )
                     ,1,1
                     )
              ,'1','00000'
              ,'2','00000'
              ,'3','00000'
              ,'4','00000'
              ,'5','00000'
              ,GLC.segment2
              )                                                                                     SEGMENT2_CR
       ,DECODE(SIGN(RAL.revenue_amount)
               ,- 1,TRIM(RAD.attribute7)
               ,DECODE(TRIM(RAD.attribute10)
                      , NULL,TRIM(RAD.attribute8)
                      ,TRIM(RAD.attribute10)
                      )
              )                                                                                     SEGMENT3_CR
       ,DECODE(SIGN(RAL.revenue_amount)
               ,- 1,DECODE(TRIM(RAD.attribute10)
                          , NULL,TRIM(RAD.attribute8)
                          ,TRIM(RAD.attribute10)
                          )
               ,TRIM(RAD.attribute7)
              )                                                                                     SEGMENT3_DR
       ,DECODE(SIGN(RAL.revenue_amount)
               ,- 1,GLC.segment4
               ,DECODE(GLC.segment4
                       ,NVL(SUBSTR(HOU.name,1,6),GLC.segment4),GLC.segment4
                       ,NVL(SUBSTR(HOU.name,1,6),GLC.segment4)
                       )
              )SEGMENT4_CR
       ,DECODE(SIGN(RAL.revenue_amount)
               ,-1,DECODE(GLC.segment4
                          ,nvl(SUBSTR(HOU.name,1,6),GLC.segment4),GLC.segment4
                          ,SUBSTR(HOU.name,1,6)
                          )
               ,GLC.segment4
               )                                                                                    SEGMENT4_DR
       ,GLC.segment5                                                                                SEGMENT5
       ,DECODE((DECODE(SIGN(RAL.revenue_amount)
                       ,- 1,TRIM(RAD.attribute7)
                       ,DECODE(TRIM(RAD.attribute10)
                              , NULL,TRIM(RAD.attribute8)
                              ,TRIM(RAD.attribute10)
                              )
                       )
                )
                ,TRIM(RAD.attribute8),(XX_DERIVE_LOB_TEST(NVL(SUBSTR(HOU.name,1,6),GLC.segment4)
                                                         )
                                      )
                ,TRIM(RAD.attribute7),GLC.segment6
                ,TRIM(RAD.attribute10),(XX_DERIVE_LOB_TEST(NVL(SUBSTR(HOU.name,1,6),GLC.segment4)
                                                           )
                                       )
              )                                                                                     SEGMENT6_CR
       ,DECODE((DECODE(SIGN(RAL.revenue_amount)
                       ,- 1,DECODE(TRIM(RAD.attribute10)
                                   , NULL,TRIM(RAD.attribute8)
                                   ,TRIM(RAD.attribute10)
                                   )
                       ,TRIM(RAD.attribute7)
                       )
                )
                ,TRIM(RAD.attribute8),(XX_DERIVE_LOB_TEST(NVL(SUBSTR(HOU.name,1,6),GLC.segment4)
                                                         )
                                       )
                ,TRIM(RAD.attribute7),GLC.segment6
                ,TRIM(RAD.attribute10),(XX_DERIVE_LOB_TEST(NVL(SUBSTR(HOU.name,1,6),GLC.segment4)
                                                          )
                                        )
              )                                                                                     SEGMENT6_DR
       ,GLC.segment7                                                                                SEGMENT7
       ,ABS(ROUND(DECODE(TO_NUMBER(NVL(TRIM(RAD.attribute9),'0')) * RAL.quantity_invoiced
                         , NULL,TO_NUMBER(NVL(TRIM(RAD.attribute9),'0')) * RAL.quantity_credited
                         ,TO_NUMBER(NVL(TRIM(RAD.attribute9),'0')) * RAL.quantity_invoiced
                         )
                  ,2
                  )
           )                                                                                        AMOUNT
       ,TO_CHAR(RAD.gl_date,'YYYY/MM/DD')                                                           REF1
       ,RTA.attribute14                                                                             REF20
       ,RAD.cust_trx_line_gl_dist_id                                                                REF21
       ,RAL.sales_order                                                                             REF22
       ,RAL.sales_order_line                                                                        REF23
       ,RAL.customer_trx_id                                                                         REF24
       ,TRIM(RAD.attribute7)                                                                        REF25
       ,TRIM(RAD.attribute8)                                                                        REF26
       ,TRIM(RAD.attribute9)                                                                        REF27
       ,RAD.attribute11                                                                             REF28
       ,RAL.description                                                                             REF29
       ,RAL.customer_trx_line_id                                                                    REF30
       ,99900                                                                                       GRP_ID
       ,ABS((DECODE(TO_NUMBER(NVL(TRIM(RAD.attribute9),'0')) * RAL.quantity_invoiced, NULL
                 ,RAL.quantity_credited
                 ,RAL.quantity_invoiced)))                                                           QTY
       ,RAL.customer_trx_id                                                                          CUST_TRX_ID
       ,RAL.customer_trx_line_id                                                                     CUST_TRX_LINE_ID
       ,RAD.cust_trx_line_gl_dist_id                                                                 CUST_GL_DIST_ID
       ,RTA.attribute14                                                                              ATT_14
       ,RAL.sales_order_line                                                                         ATT_15
       ,99999                                                                                        GP_ID
       ,RAD.attribute11                                                                              DFF
       ,RAL.sales_order                                                                              ORDER_NUM
       ,RAL.description                                                                              DESCR
       ,'VALID'                                                                                      VAL
       ,'BALANCED'                                                                                   BAL
  FROM  ra_customer_trx_all RTA
       ,ra_cust_trx_line_gl_dist_all RAD
       ,ra_customer_trx_lines_all RAL
       ,gl_code_combinations GLC
       ,gl_sets_of_books GLS
       ,hr_organization_units HOU
, ra_cust_trx_types_all        RCTTA   -- Added By GAGARWAL on 11-MAR-2011 for SDR changes

  WHERE  RAD.account_class = 'REV'
  --AND  RAD.attribute_category = 'SALES_ACCT'
AND  RAD.attribute_category in ( 'SALES_ACCT','POS')
AND  RTA.CUST_TRX_TYPE_ID = RCTTA.CUST_TRX_TYPE_ID -- Added By GAGARWAL on 11-MAR-2011 for SDR changes
  AND  RAD.attribute6 IN ('N','E')
  AND  RAD.gl_posted_date IS NOT NULL
  AND  RAD.set_of_books_id = ln_set_of_books_id
  AND  RAL.customer_trx_line_id = RAD.customer_trx_line_id
--  AND  RTA.trx_number=RAL.sales_order
AND  RTA.customer_trx_id=RAL.customer_trx_id
  AND  GLS.set_of_books_id = RAD.set_of_books_id
  AND  GLC.code_combination_id = RAD.code_combination_id
  AND  HOU.organization_id(+) = RAL.warehouse_id
  AND  RAD.cust_trx_line_gl_dist_id BETWEEN p_cust_trx_id_low AND p_cust_trx_id_high
  AND  RAD.gl_date  between TO_DATE(p_gl_date_low, 'RRRR/MM/DD HH24:MI:SS') and TO_DATE(p_gl_date_high, 'RRRR/MM/DD HH24:MI:SS') ;
TYPE c_insert_je_lines_stat_type  IS TABLE OF VARCHAR2(7);
v_insert_je_lines_stat c_insert_je_lines_stat_type  ;
TYPE c_insert_je_lines_sob_type  IS TABLE OF ra_cust_trx_line_gl_dist_all.set_of_books_id%TYPE;
v_insert_je_lines_sob c_insert_je_lines_sob_type  ;
TYPE c_insert_je_lines_acct_date_ty  IS TABLE OF ra_cust_trx_line_gl_dist_all.gl_date%TYPE;
v_insert_je_lines_acct_date c_insert_je_lines_acct_date_ty ;
TYPE c_insert_je_lines_curr_code_ty  IS TABLE OF gl_sets_of_books.currency_code%TYPE;
v_insert_je_lines_curr_code c_insert_je_lines_curr_code_ty  ;
TYPE c_insert_je_lines_date_crtd_ty  IS TABLE OF DATE;
v_insert_je_lines_date_crtd c_insert_je_lines_date_crtd_ty  ;
TYPE c_insert_je_lines_crtd_by_ty  IS TABLE OF NUMBER;
v_insert_je_lines_crtd_by c_insert_je_lines_crtd_by_ty ;
TYPE c_insert_je_lines_act_flg_type  IS TABLE OF CHAR;
v_insert_je_lines_act_flg c_insert_je_lines_act_flg_type ;
TYPE c_insert_je_lines_je_cat_type  IS TABLE OF VARCHAR2(30);
v_insert_je_lines_je_cat c_insert_je_lines_je_cat_type ;
TYPE c_insert_je_lines_je_src_type  IS TABLE OF VARCHAR2(10);
v_insert_je_lines_je_src c_insert_je_lines_je_src_type ;
TYPE c_insert_je_lines_segment1_cr  IS TABLE OF VARCHAR2(20);
v_insert_je_lines_segment1_cr c_insert_je_lines_segment1_cr ;
TYPE c_insert_je_lines_segment1_dr  IS TABLE OF VARCHAR2(20);
v_insert_je_lines_segment1_dr c_insert_je_lines_segment1_dr ;
TYPE c_insert_je_lines_seg2_dr_type  IS TABLE OF VARCHAR2(20);
v_insert_je_lines_seg2_dr c_insert_je_lines_seg2_dr_type  ;
TYPE c_insert_je_lines_seg2_cr_type  IS TABLE OF VARCHAR2(20);
v_insert_je_lines_seg2_cr c_insert_je_lines_seg2_cr_type  ;
TYPE c_insert_je_lines_segment3_cr  IS TABLE OF VARCHAR2(20);
v_insert_je_lines_segment3_cr c_insert_je_lines_segment3_cr  ;
TYPE c_insert_je_lines_segment3_dr  IS TABLE OF VARCHAR2(20);
v_insert_je_lines_segment3_dr c_insert_je_lines_segment3_dr  ;
TYPE c_insert_je_lines_segment4_cr  IS TABLE OF VARCHAR2(20);
v_insert_je_lines_segment4_cr c_insert_je_lines_segment4_cr  ;
TYPE c_insert_je_lines_segment4_dr  IS TABLE OF VARCHAR2(20);
v_insert_je_lines_segment4_dr c_insert_je_lines_segment4_dr  ;
TYPE c_insert_je_lines_seg5_type  IS TABLE OF gl_code_combinations.segment5%TYPE;
v_insert_je_lines_seg5 c_insert_je_lines_seg5_type ;
TYPE c_insert_je_lines_segment6_cr  IS TABLE OF VARCHAR2(20);
v_insert_je_lines_segment6_cr c_insert_je_lines_segment6_cr  ;
TYPE c_insert_je_lines_segment6_dr  IS TABLE OF VARCHAR2(20);
v_insert_je_lines_segment6_dr c_insert_je_lines_segment6_dr  ;
TYPE c_insert_je_lines_seg7  IS TABLE OF gl_code_combinations.segment7%TYPE;
v_insert_je_lines_seg7 c_insert_je_lines_seg7  ;
TYPE c_insert_je_lines_amount_type  IS TABLE OF NUMBER;
v_insert_je_lines_amount c_insert_je_lines_amount_type  ;
TYPE c_insert_je_lines_ref1_type  IS TABLE OF VARCHAR2(15);
v_insert_je_lines_ref1 c_insert_je_lines_ref1_type;
TYPE c_insert_je_lines_ref20_type  IS TABLE OF ra_customer_trx_all.attribute14%TYPE;
v_insert_je_lines_ref20 c_insert_je_lines_ref20_type;
TYPE c_insert_je_lines_ref21_type  IS TABLE OF ra_cust_trx_line_gl_dist_all.cust_trx_line_gl_dist_id%TYPE;
v_insert_je_lines_ref21 c_insert_je_lines_ref21_type  ;
TYPE c_insert_je_lines_ref22_type  IS TABLE OF ra_customer_trx_lines_all.sales_order%TYPE;
v_insert_je_lines_ref22 c_insert_je_lines_ref22_type ;
TYPE c_insert_je_lines_ref23_type  IS TABLE OF ra_customer_trx_lines_all.sales_order_line%TYPE;
v_insert_je_lines_ref23 c_insert_je_lines_ref23_type ;
TYPE c_insert_je_lines_ref24_type  IS TABLE OF ra_customer_trx_lines_all.customer_trx_id%TYPE;
v_insert_je_lines_ref24 c_insert_je_lines_ref24_type ;
TYPE c_insert_je_lines_ref25_type  IS TABLE OF ra_cust_trx_line_gl_dist_all.attribute7%TYPE;
v_insert_je_lines_ref25 c_insert_je_lines_ref25_type  ;
TYPE c_insert_je_lines_ref26_type  IS TABLE OF ra_cust_trx_line_gl_dist_all.attribute8%TYPE;
v_insert_je_lines_ref26 c_insert_je_lines_ref26_type ;
TYPE c_insert_je_lines_ref27_type  IS TABLE OF ra_cust_trx_line_gl_dist_all.attribute9%TYPE;
v_insert_je_lines_ref27 c_insert_je_lines_ref27_type ;
TYPE c_insert_je_lines_ref28_type  IS TABLE OF ra_cust_trx_line_gl_dist_all.attribute11%TYPE;
v_insert_je_lines_ref28 c_insert_je_lines_ref28_type;
TYPE c_insert_je_lines_ref29_type  IS TABLE OF ra_customer_trx_lines_all.description%TYPE;
v_insert_je_lines_ref29 c_insert_je_lines_ref29_type ;
TYPE c_insert_je_lines_ref30_type  IS TABLE OF ra_customer_trx_lines_all.customer_trx_line_id%TYPE;
v_insert_je_lines_ref30 c_insert_je_lines_ref30_type  ;
TYPE c_insert_je_lines_grp_id_type  IS TABLE OF NUMBER;
v_insert_je_lines_grp_id c_insert_je_lines_grp_id_type ;
TYPE c_insert_je_lines_qty_type  IS TABLE OF NUMBER;
v_insert_je_lines_qty c_insert_je_lines_qty_type;
TYPE c_insert_je_lines_cust_trx_id  IS TABLE OF ra_customer_trx_lines_all.customer_trx_id%TYPE;
v_insert_je_lines_cust_trx_id c_insert_je_lines_cust_trx_id ;
TYPE c_insert_je_lines_cust_trx  IS TABLE OF ra_customer_trx_lines_all.customer_trx_line_id%TYPE;
v_insert_je_lines_cust_trx_lin c_insert_je_lines_cust_trx  ;
TYPE c_insert_je_lines_cust_gl  IS TABLE OF ra_cust_trx_line_gl_dist_all.cust_trx_line_gl_dist_id%TYPE;
v_insert_je_lines_cust_gl_dist c_insert_je_lines_cust_gl  ;
TYPE c_insert_je_lines_att_14_type  IS TABLE OF ra_customer_trx_all.attribute14%TYPE;
v_insert_je_lines_att_14 c_insert_je_lines_att_14_type  ;
TYPE c_insert_je_lines_att_15_type  IS TABLE OF ra_customer_trx_lines_all.sales_order_line%TYPE;
v_insert_je_lines_att_15 c_insert_je_lines_att_15_type  ;
TYPE c_insert_je_lines_gp_id_type  IS TABLE OF NUMBER;
v_insert_je_lines_gp_id c_insert_je_lines_gp_id_type ;
TYPE c_insert_je_lines_dff_type  IS TABLE OF ra_cust_trx_line_gl_dist_all.attribute11%TYPE;
v_insert_je_lines_dff c_insert_je_lines_dff_type ;
TYPE c_insert_je_lines_order_num  IS TABLE OF ra_customer_trx_lines_all.sales_order%TYPE;
v_insert_je_lines_order_num c_insert_je_lines_order_num ;
TYPE c_insert_je_lines_descr_type  IS TABLE OF ra_customer_trx_lines_all.description%TYPE;
v_insert_je_lines_descr c_insert_je_lines_descr_type  ;
TYPE c_insert_je_lines_val_type  IS TABLE OF VARCHAR2(7);
v_insert_je_lines_val c_insert_je_lines_val_type  ;
TYPE c_insert_je_lines_bal_type  IS TABLE OF VARCHAR2(10);
v_insert_je_lines_bal c_insert_je_lines_bal_type  ;
 BEGIN
       ln_user_id := FND_GLOBAL.USER_ID;
       gc_debug_flg := p_debug_flg;
-------------------------------------------------------------------
        --SET Context to Operating unit or register by operating unit
ln_set_of_books_id :=  fnd_profile.value('GL_SET_OF_BKS_ID');
FND_FILE.PUT_LINE(FND_FILE.LOG,'SOB Id is '      ||  ln_set_of_books_id);
FND_FILE.PUT_LINE(FND_FILE.LOG,'Source Name is ' ||  p_source_name);
OPEN c_insert_je_lines_test;
------------ Get the invoice lines data up to the limit------------
FETCH c_insert_je_lines_test BULK COLLECT INTO v_insert_je_lines_stat,
v_insert_je_lines_sob,
v_insert_je_lines_acct_date,
v_insert_je_lines_curr_code,
v_insert_je_lines_date_crtd,
v_insert_je_lines_crtd_by,
v_insert_je_lines_act_flg,
v_insert_je_lines_je_cat,
v_insert_je_lines_je_src,
v_insert_je_lines_segment1_cr,
v_insert_je_lines_segment1_dr,
v_insert_je_lines_seg2_dr,
v_insert_je_lines_seg2_cr,
v_insert_je_lines_segment3_cr,
v_insert_je_lines_segment3_dr,
v_insert_je_lines_segment4_cr,
v_insert_je_lines_segment4_dr,
v_insert_je_lines_seg5,
v_insert_je_lines_segment6_cr,
v_insert_je_lines_segment6_dr,
v_insert_je_lines_seg7,
v_insert_je_lines_amount,
v_insert_je_lines_ref1,
v_insert_je_lines_ref20,
v_insert_je_lines_ref21,
v_insert_je_lines_ref22,
v_insert_je_lines_ref23,
v_insert_je_lines_ref24,
v_insert_je_lines_ref25,
v_insert_je_lines_ref26,
v_insert_je_lines_ref27,
v_insert_je_lines_ref28,
v_insert_je_lines_ref29,
v_insert_je_lines_ref30,
v_insert_je_lines_grp_id,
v_insert_je_lines_qty,
v_insert_je_lines_cust_trx_id,
v_insert_je_lines_cust_trx_lin,
v_insert_je_lines_cust_gl_dist,
v_insert_je_lines_att_14,
v_insert_je_lines_att_15,
v_insert_je_lines_gp_id,
v_insert_je_lines_dff,
v_insert_je_lines_order_num,
v_insert_je_lines_descr,
v_insert_je_lines_val,
v_insert_je_lines_bal ;-- LIMIT P_BATCH_SIZE;


  SELECT gl_interface_control_s.nextval
  INTO   ln_group_id
  FROM   dual;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Group Id is ' ||  ln_group_id);




 --------------------------------------------------
 ---------To Select Period Name--------------------
 --------------------------------------------------
       SELECT period_name
       INTO lc_period_end
       FROM gl_periods GP
       WHERE GP.period_set_name = 'OD 445 CALENDAR'
       AND TO_DATE(p_gl_date_high, 'RRRR/MM/DD HH24:MI:SS')  BETWEEN GP.start_date AND GP.end_date;
 -------------------------------------------------------------------------------------------
-----------------------------INSERTION INTO XX_GL_INTERFACE_NA_STG  Table-------------------
  ------------------------------------------------------------------------------------------
       lc_debug_msg := 'Before Insertion of Credit Line into XX_GL_INTERFACE_NA_STG.';
       DEBUG_MESSAGE(lc_debug_msg);
FND_FILE.PUT_LINE(FND_FILE.LOG,'Before ' );
----------------------CREDIT LINE------------------------------------------------------------------------
 -- Loop through the fetched array to assign the needed non-null values to create the credit lines for JE
      FORALL i IN v_insert_je_lines_stat.FIRST .. v_insert_je_lines_stat.LAST
      INSERT INTO XX_GL_INTERFACE_NA_STG (status
                                         ,set_of_books_id
                                         ,accounting_date
                                         ,currency_code
                                         ,date_created
                                         ,created_by
                                         ,actual_flag
                                         ,user_je_category_name
                                         ,user_je_source_name
                                         ,segment1
                                         ,segment2
                                         ,segment3
                                         ,segment4
                                         ,segment5
                                         ,segment6
                                         ,segment7
                                         ,code_combination_id
                                         ,entered_dr
                                         ,entered_cr
                                         ,reference1
                                         ,reference20
                                         ,reference21
                                         ,reference22
                                         ,reference23
                                         ,reference24
                                         ,reference25
                                         ,reference26
                                         ,reference27
                                         ,reference28
                                         ,reference29
                                         ,reference30
                                         ,group_id
                                         ,attribute10
                                         ,attribute11
                                         ,attribute12
                                         ,attribute13
                                         ,attribute14
                                         ,attribute15
                                         ,attribute16
                                         ,attribute18
                                         ,attribute19
                                         ,attribute20
                                         ,derived_val
                                         ,derived_sob
                                         ,balanced
                                         )
                        VALUES( v_insert_je_lines_stat(i)
                               ,v_insert_je_lines_sob(i)
                               ,v_insert_je_lines_acct_date(i)
                               ,v_insert_je_lines_curr_code(i)
                               ,v_insert_je_lines_date_crtd(i)
                               ,v_insert_je_lines_crtd_by(i)
                               ,v_insert_je_lines_act_flg(i)
                               ,v_insert_je_lines_je_cat(i)
                               ,v_insert_je_lines_je_src(i)
                               ,v_insert_je_lines_segment1_cr(i)
                               ,v_insert_je_lines_seg2_cr(i)
                               ,v_insert_je_lines_segment3_cr(i)
                               ,v_insert_je_lines_segment4_cr(i)
                               ,v_insert_je_lines_seg5(i)
                               ,v_insert_je_lines_segment6_cr(i)
                               ,v_insert_je_lines_seg7(i)
                               ,GET_CODE_COMBINATION_ID(v_insert_je_lines_segment1_cr(i),v_insert_je_lines_seg2_cr(i)
                                                       ,v_insert_je_lines_segment3_cr(i),v_insert_je_lines_segment4_cr(i)
                                                       ,v_insert_je_lines_seg5(i),v_insert_je_lines_segment6_cr(i),v_insert_je_lines_seg7(i))-- Added For Defect 3098
                               ,NULL
                               ,v_insert_je_lines_amount(i)
                               ,v_insert_je_lines_ref1(i)
                               ,v_insert_je_lines_ref20(i)
                               ,v_insert_je_lines_ref21(i)
                               ,v_insert_je_lines_ref22(i)
                               ,v_insert_je_lines_ref23(i)
                               ,v_insert_je_lines_ref24(i)
                               ,v_insert_je_lines_ref25(i)
                               ,v_insert_je_lines_ref26(i)
                               ,v_insert_je_lines_ref27(i)
                               ,v_insert_je_lines_ref28(i)
                               ,v_insert_je_lines_ref29(i)
                               ,v_insert_je_lines_ref30(i)
                               ,ln_group_id
                               ,v_insert_je_lines_qty(i)
                               ,v_insert_je_lines_cust_trx_id(i)
                               ,v_insert_je_lines_cust_trx_lin(i)
                               ,v_insert_je_lines_cust_gl_dist(i)
                               ,v_insert_je_lines_att_14(i)
                               ,v_insert_je_lines_att_15(i)
                               ,ln_group_id
                               ,v_insert_je_lines_dff(i)
                               ,v_insert_je_lines_order_num(i)
                               ,v_insert_je_lines_descr(i)
                               ,v_insert_je_lines_val(i)
                               ,v_insert_je_lines_val(i)
                               ,v_insert_je_lines_bal(i)
                               );
            lc_debug_msg := 'Insertion of Credit Line into XX_GL_INTERFACE_NA_STG Successfully';
            DEBUG_MESSAGE(lc_debug_msg);
---------------------------------DEBIT LINE---------------------------------------------------
          lc_debug_msg := 'Before Insertion of Debit Line into XX_GL_INTERFACE_NA_STG.';
          DEBUG_MESSAGE(lc_debug_msg);
      FORALL i IN v_insert_je_lines_stat.FIRST .. v_insert_je_lines_stat.LAST
       INSERT INTO XX_GL_INTERFACE_NA_STG(status
                                         ,set_of_books_id
                                         ,accounting_date
                                         ,currency_code
                                         ,date_created
                                         ,created_by
                                         ,actual_flag
                                         ,user_je_category_name
                                         ,user_je_source_name
                                         ,segment1
                                         ,segment2
                                         ,segment3
                                         ,segment4
                                         ,segment5
                                         ,segment6
                                         ,segment7
                                         ,code_combination_id
                                         ,entered_dr
                                         ,entered_cr
                                         ,reference1
                                         ,reference20
                                         ,reference21
                                         ,reference22
                                         ,reference23
                                         ,reference24
                                         ,reference25
                                         ,reference26
                                         ,reference27
                                         ,reference28
                                         ,reference29
                                         ,reference30
                                         ,group_id
                                         ,attribute10
                                         ,attribute11
                                         ,attribute12
                                         ,attribute13
                                         ,attribute14
                                         ,attribute15
                                         ,attribute16
                                         ,attribute18
                                         ,attribute19
                                         ,attribute20
                                         ,derived_val
                                         ,derived_sob
                                         ,balanced
                                          )
                         VALUES(v_insert_je_lines_stat(i)
                               ,v_insert_je_lines_sob(i)
                               ,v_insert_je_lines_acct_date(i)
                               ,v_insert_je_lines_curr_code(i)
                               ,v_insert_je_lines_date_crtd(i)
                               ,v_insert_je_lines_crtd_by(i)
                               ,v_insert_je_lines_act_flg(i)
                               ,v_insert_je_lines_je_cat(i)
                               ,v_insert_je_lines_je_src(i)
                               ,v_insert_je_lines_segment1_dr(i)
                               ,v_insert_je_lines_seg2_dr(i)
                               ,v_insert_je_lines_segment3_dr(i)
                               ,v_insert_je_lines_segment4_dr(i)
                               ,v_insert_je_lines_seg5(i)
                               ,v_insert_je_lines_segment6_dr(i)
                               ,v_insert_je_lines_seg7(i)
                               ,GET_CODE_COMBINATION_ID(v_insert_je_lines_segment1_dr(i),v_insert_je_lines_seg2_dr(i)
                                                       ,v_insert_je_lines_segment3_dr(i),v_insert_je_lines_segment4_dr(i)
                                               ,v_insert_je_lines_seg5(i),v_insert_je_lines_segment6_dr(i),v_insert_je_lines_seg7(i))-- Added For Defect 3098
                               ,v_insert_je_lines_amount(i)
                               ,NULL
                               ,v_insert_je_lines_ref1(i)
                               ,v_insert_je_lines_ref20(i)
                               ,v_insert_je_lines_ref21(i)
                               ,v_insert_je_lines_ref22(i)
                               ,v_insert_je_lines_ref23(i)
                               ,v_insert_je_lines_ref24(i)
                               ,v_insert_je_lines_ref25(i)
                               ,v_insert_je_lines_ref26(i)
                               ,v_insert_je_lines_ref27(i)
                               ,v_insert_je_lines_ref28(i)
                               ,v_insert_je_lines_ref29(i)
                               ,v_insert_je_lines_ref30(i)
                               ,ln_group_id
                               ,v_insert_je_lines_qty(i)
                               ,v_insert_je_lines_cust_trx_id(i)
                               ,v_insert_je_lines_cust_trx_lin(i)
                               ,v_insert_je_lines_cust_gl_dist(i)
                               ,v_insert_je_lines_att_14(i)
                               ,v_insert_je_lines_att_15(i)
                               ,ln_group_id
                               ,v_insert_je_lines_dff(i)
                               ,v_insert_je_lines_order_num(i)
                               ,v_insert_je_lines_descr(i)
                               ,v_insert_je_lines_val(i)
                               ,v_insert_je_lines_val(i)
                               ,v_insert_je_lines_bal(i))
                               ;
         lc_debug_msg := 'Insertion of Debit Line into XX_GL_INTERFACE_NA_STG Successfully';
         DEBUG_MESSAGE(lc_debug_msg);
---------------------------Record Count Check on Staging Table----------------------------------
              SELECT COUNT(*)
              INTO gn_rec_cnt
              FROM XX_GL_INTERFACE_NA_STG
              WHERE group_id=ln_group_id
              AND user_je_source_name=p_source_name
              AND set_of_books_id  = ln_set_of_books_id;
              FND_FILE.PUT_LINE(FND_FILE.LOG,'No of records inserted into staging table'
                                             ||'   '
                                             || 'is'
                                             ||'   '
                                             || gn_rec_cnt
                                );
                SELECT FCR.parent_request_id
                INTO  ln_parent_request_id
                FROM fnd_concurrent_requests FCR
                WHERE FCR.request_id=ln_conc_request_id ;
         lc_debug_msg := 'Calling PROCESS_JRNL_LINES Procedure to Insert Data into the HV Control and HV GL Interface Table';
         DEBUG_MESSAGE(lc_debug_msg);
--------------------------------------------------------------------------------------------------------------------------------
----------------------Insert Data into the HV Control and HV GL Interface Table------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
                                 PROCESS_JRNL_LINES(p_group_id              => ln_group_id
                                                   ,p_source_nm             => p_source_name
                                                   ,p_debug_flag            => gc_debug_flg
                                                   ,p_otc_cycle_run_date    => p_otc_cycle_run_date
                                                   ,p_otc_cycle_wave_num    => p_otc_cycle_wave_num
                                                   ,p_period_name           => lc_period_end
                                                   ,p_parent_request_id     => ln_parent_request_id
                                                   );
                                 COMMIT;
           lc_debug_msg := 'Insertion into  HV Control and Interface tables are Successful';
           DEBUG_MESSAGE(lc_debug_msg);
--------------------------------------------------------------------------------------------------------------------------------
-----------------Calling CREATE_OUTPUT Procedure to Print the Details of the Coressponding and Child Program--------------------
--------------------------------------------------------------------------------------------------------------------------------
           lc_debug_msg := 'Calling CREATE_OUTPUT to print Details of the  Child Processes Submitted';
           DEBUG_MESSAGE(lc_debug_msg);
                                  CREATE_OUTPUT (p_source_name              => p_source_name
                                                ,p_debug_flag               => gc_debug_flg
                                                ,p_batch_size               => p_batch_size
                                                ,p_set_of_books_id          => ln_set_of_books_id
                                                ,p_gl_date_low              => p_gl_date_low
                                                ,p_gl_date_high             => p_gl_date_high
                                                ,p_otc_cycle_run_date       => p_otc_cycle_run_date
                                                ,p_otc_cycle_wave_num       => p_otc_cycle_wave_num
                                                ,p_parent_request_id        => ln_parent_request_id
                                                ,p_child_request_id         => ln_conc_request_id
                                                ,p_cust_trx_low             => p_cust_trx_id_low
                                                ,p_cust_trx_high            => p_cust_trx_id_high
                                                );
             lc_debug_msg := 'Child Process Details are printed Successfully';
             DEBUG_MESSAGE(lc_debug_msg);
    CLOSE c_insert_je_lines_test ;
   EXCEPTION
         WHEN NO_GROUP_ID_FOUND THEN
                lc_debug_msg := '    No data exists for GROUP_ID: '   || ln_group_id     ||' on staging table ';
                FND_MESSAGE.CLEAR();
                FND_MESSAGE.SET_NAME('FND','FS-UNKNOWN');
                FND_MESSAGE.SET_TOKEN('ERROR',lc_debug_msg);
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'No records or invalid group ID/source name'
                                             ||' on staging table');
                 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No records or invalid group ID/source name'
                                             ||' on staging table');
                x_return_code    := 2;
                x_return_message := fnd_message.get();
         WHEN OTHERS THEN
               FND_MESSAGE.CLEAR();
               FND_MESSAGE.SET_NAME('FND','FS-UNKNOWN');
               FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
               x_return_code    := 1;
               x_return_message := fnd_message.get();
               ROLLBACK;
    END PROCESS_JOURNALS_CHILD;
----------------------------------------------------------------------------------------------------------------------------
-----------------Commented XX_GL_COGS_INT_MASTER_PROC for CR 661 and Rewritten with Modifications as below------------------
----------------------------------------------------------------------------------------------------------------------------
-- +===================================================================+
-- | Name  : XX_GL_COGS_INT_MASTER_PROC                                |
-- | Description  : The procedure used to for running mulitple threads |
-- |                of COGS program                                    |
-- |                                                                   |
-- |                                                                   |
-- | Parameters :p_source_name,  p_debug_flg, P_BATCH_SIZE             |
-- |                                                                   |
-- |                                                                   |
-- | Returns :  x_return_message, x_return_code                        |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
/*PROCEDURE XX_GL_COGS_INT_MASTER_PROC(
                                     x_return_message    OUT  VARCHAR2
                                    ,x_return_code       OUT  VARCHAR2
                                    ,p_source_name       IN   VARCHAR2
                                    ,p_debug_flg         IN   VARCHAR2 DEFAULT 'N'
                                    ,p_batch_size        IN   NUMBER DEFAULT '50000'
                                    ,p_set_of_books_id    IN NUMBER
                                    ,p_gl_date_low           IN   VARCHAR2
                                    ,p_gl_date_high          IN   VARCHAR2
                                   )
IS
        ln_conc_request_id      NUMBER;
        ln_cnt                  NUMBER;
       -- lb_bool                 BOOLEAN;
        ----lc_phase                VARCHAR2(50);
        --lc_status               VARCHAR2(50);
        ----lc_devphase             VARCHAR2(50);
       -- lc_devstatus            VARCHAR2(50);
        --lc_message              VARCHAR2(250);
       -- lc_mail_subject         VARCHAR2(250);
        lc_debug_msg            VARCHAR2(2000);
        ---lc_sr_file_name         VARCHAR2(1000);
        --lc_dst_file_name        VARCHAR2(1000);
       -- --lc_source_file          VARCHAR2(50);
       -- lc_dest_file            VARCHAR2(50);
       -- lc_source_file_path     VARCHAR2(500) := '$APPLCSF/$APPLOUT';
       -- lc_dest_file_path       VARCHAR2(500) := '$XXFIN_DATA/inbound';
       -- gc_email_lkup           XX_FIN_TRANSLATEVALUES.source_value1%TYPE;
        ln_group_id             XX_GL_INTERFACE_NA_STG.group_id%TYPE;
      --  ln_conc_id              INTEGER;
        ln_upper                NUMBER;
        ln_lower                NUMBER;
       -- ln_last_inv_id          ra_customer_trx_all.trx_number%TYPE;
        --ln_first_inv_id         ra_customer_trx_all.trx_number%TYPE;
        ln_cntr                 NUMBER :=0;
        ln_cust_trx_id_low      NUMBER;
        ln_cust_trx_id_high     NUMBER;
      --  lc_first_rec             VARCHAR(1);
       -- ln_jn_request_id        FND_CONCURRENT_REQUESTS.request_id%TYPE;
       -- lc_jn_meaning           FND_LOOKUPS.meaning%TYPE;
       -- lc_temp_email           VARCHAR2(2000);
 TYPE t_insert_scheduler IS TABLE OF VARCHAR2(1000) INDEX BY BINARY_INTEGER;
        v_insert_scheduler  t_insert_scheduler;
     CURSOR lcu_scheduler
     IS
     SELECT RAD.cust_trx_line_gl_dist_id
     FROM   ra_customer_trx_all          RTA
           ,ra_cust_trx_line_gl_dist_all RAD
           ,ra_customer_trx_lines_all    RAL
     WHERE  RAD.account_class        = 'REV'
     AND    RAD.attribute_category   = 'SALES_ACCT'
     AND    RAD.attribute6           IN ('N','E')
     AND    RAD.gl_posted_date       IS NOT NULL
     AND    RAD.set_of_books_id      = p_set_of_books_id
     AND    RAL.customer_trx_line_id =  RAD.customer_trx_line_id
     AND    RTA.customer_trx_id      =  RAL.customer_trx_id
     AND    RAD.gl_date between to_date(p_gl_date_low, 'RRRR/MM/DD HH24:MI:SS') and to_date(p_gl_date_high, 'RRRR/MM/DD HH24:MI:SS')
     ORDER BY RAD.cust_trx_line_gl_dist_id;
           CURSOR lcu_conc_req (p_master_request_id IN NUMBER)
           IS
           SELECT FCR.request_id
                 ,FLP.meaning
           FROM   fnd_concurrent_requests FCR
                 ,fnd_concurrent_programs FCP
                 ,FND_LOOKUPS             FLP
           WHERE  FCR.parent_request_id       = p_master_request_id
           AND    FCR.concurrent_program_id   = FCP.concurrent_program_id
           AND    FLP.lookup_code             = FCR.status_code
           AND    FLP.lookup_type             = 'CP_STATUS_CODE'
           AND    FCP.concurrent_program_name = 'XX_GL_COGS_INTERFACE_CHILD';
              CURSOR lcu_conc_req_stat(p_master_request_id IN NUMBER)
              IS
              SELECT FCP.user_concurrent_program_name  conc_name
                   ,FCR.request_id  req_id
                    ,FLP.meaning   meaning
              FROM   fnd_concurrent_requests FCR
                    ,fnd_concurrent_programs_vl FCP
                    ,FND_LOOKUPS             FLP
              WHERE  FCR.priority_request_id       =p_master_request_id
              AND    FCR.concurrent_program_id   = FCP.concurrent_program_id
              AND    FLP.lookup_code             = FCR.status_code
              AND    FLP.lookup_type             = 'CP_STATUS_CODE'
              AND    FCP.concurrent_program_name IN ('XX_GL_COGS_INTERFACE_CHILD','GLLEZL')
             ORDER BY FCR.request_id;
      BEGIN
    IF TO_NUMBER(NVL(FND_CONC_GLOBAL.request_data,-1)) >= 1 THEN
                      -- FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_gl_date_low);
                       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'OFFICE DEPOT, INC'
                                               ||'                            '
                                               ||'OD GL COGS Report Status'
                                               ||'               '||'Report Date: '
                                               ||to_char(sysdate,'DD-MON-YYYY HH24:MI'));
                       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Request ID: '|| gn_request_id);
                     FOR lcu_conc_req_rec IN lcu_conc_req(gn_request_id)
                     LOOP
/*
                         ln_conc_id := fnd_request.submit_request(
                                                                application => 'XXFIN'
                                                               ,program     => 'XXGLINTERFACEEMAIL'
                                                               ,description => NULL
                                                               ,start_time  => SYSDATE
                                                               ,sub_request => FALSE
                                                               ,argument1   => lcu_conc_req_rec.request_id
                                                               ,argument2   => gc_email_lkup
                                                               ,argument3   => 'Journal Import Execution Report for Request'
                                                               );
                        lc_source_file       := 'o'||lcu_conc_req_rec.request_id||'.out';
                        lc_dest_file         := gn_request_id||'_'||lcu_conc_req_rec.request_id||'.txt';
                        lc_sr_file_name  := lc_source_file_path || '/' || lc_source_file;
                        lc_dst_file_name    := lc_dest_file_path   || '/' || lc_dest_file;
                        ln_conc_id := FND_REQUEST.SUBMIT_REQUEST ('xxfin'
                                                                 ,'XXCOMFILCOPY'
                                                                 ,''
                                                                 ,''
                                                                 ,FALSE
                                                                 ,lc_sr_file_name
                                                                 ,lc_dst_file_name
                                                                 ,NULL
                                                                 ,NULL
                                                                 );
                        COMMIT;
                     END LOOP;
                       lc_mail_subject := 'OD GL COGS Import Interface Status_';
                       lc_debug_msg    := 'Emailing output report: gn_request_id=> '
                                       ||gn_request_id || ' gc_source_name=> ' ||p_source_name
                                       || ' lc_mail_subject=> ' || lc_mail_subject;
                       DEBUG_MESSAGE (lc_debug_msg,1);
                       gc_email_lkup := p_source_name;
                        XX_GL_COGS_INT_MASTER_PKG.XX_CONCAT_EMAIL_OUTPUT (p_request_id     =>gn_request_id
                                                                         ,p_email_lookup   =>p_source_name
                                                                         ,p_email_subject  =>lc_mail_subject
                                                                         );
XX_EXCEPTION_REPORT_PROC;
                        ln_conc_id := fnd_request.submit_request(
                                                 application => 'XXFIN'
                                                ,program     => 'XXODCOGSM'
                                                ,description => NULL
                                                ,start_time  => SYSDATE
                                                ,sub_request => FALSE
                                                ,argument1   => NULL
                                                ,argument2   => lc_temp_email
                                                ,argument3   => lc_mail_subject
                                                ,argument4   => NULL
                                                ,argument5   => 'Y'
                                                ,argument6   => gn_request_id
                                                         );
                       COMMIT;
                       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Concurrent Program Name:');
                       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
                       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
                       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('REQUEST ID',20,' ')
                                                       ||RPAD('REQUEST STATUS',20));
                       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('----------',20,' ')
                                                       ||RPAD('--------------',20));
                      FOR lcu_conc_req_stat_rec IN lcu_conc_req_stat(gn_request_id)
                       LOOP
                            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(lcu_conc_req_stat_rec.conc_name,20,' ')
                                               ||RPAD(lcu_conc_req_stat_rec.req_id,20)
                                               ||RPAD(lcu_conc_req_stat_rec.meaning,20));
                       END LOOP;
                            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
                            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'------------------------CHILD REQUEST STATUS-----------------------------------------------------------');
                            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
                            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('PROGRAM NAME',30,' ')
                                                            ||RPAD('REQUEST ID',60,' ')
                                                            ||RPAD('REQUEST STATUS',20,' '));
                            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('-----------',30,' ')
                                                            ||RPAD('------------------',60,' ')
                                                            ||RPAD('----------------',20,' '));
                      FOR lcu_conc_req_stat_rec IN lcu_conc_req_stat(gn_request_id)
                      LOOP
                            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(lcu_conc_req_stat_rec.conc_name,30,' ')
                                                            ||RPAD(lcu_conc_req_stat_rec.req_id,60,' ')
                                                            ||RPAD(lcu_conc_req_stat_rec.meaning,20,' '));
                      END LOOP;
                      ln_conc_id := fnd_request.submit_request(application => 'XXFIN'
                                                              ,program     => 'XXGLINTERFACEEMAIL'
                                                              ,description => NULL
                                                              ,start_time  => SYSDATE
                                                              ,sub_request => FALSE
                                                              ,argument1   => gn_request_id
                                                              ,argument2   => p_source_name
                                                              ,argument3   => lc_mail_subject
                                                              );
                        COMMIT;
          x_return_message := 'COMPLETED MASTER PROGRAM SUCCESSFULLY-EXITING';
          x_return_code    := 0;
          RETURN;
     ELSE
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Befor Restart of Master program');
       FND_FILE.PUT_LINE(FND_FILE.LOG,FND_CONC_GLOBAL.request_data);
     OPEN lcu_scheduler;
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Scheduler Program - open loop');
       LOOP
         FETCH lcu_scheduler BULK COLLECT INTO v_insert_scheduler LIMIT P_BATCH_SIZE;
         IF (NVL(v_insert_scheduler.FIRST,0) = 0 AND  ln_cntr = 0)  THEN
            EXIT;
         ELSIF (NVL(v_insert_scheduler.FIRST,0) = 0 AND  ln_cntr > 0) THEN
             EXIT;
         ELSE
            ln_upper            := v_insert_scheduler.LAST;
            ln_lower            := v_insert_scheduler.FIRST;
            ln_cust_trx_id_low  := v_insert_scheduler(ln_lower);
            ln_cust_trx_id_high := v_insert_scheduler(ln_upper);
          --  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Cursor lvalue'||ln_cust_trx_id_low);
         --   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Cursor hvalue'||ln_cust_trx_id_high);
            ln_cntr:=ln_cntr+1;
              ln_conc_request_id := fnd_request.submit_request (
                                                                'XXFIN'
                                                               ,'XX_GL_COGS_INTERFACE_CHILD'
                                                               ,NULL
                                                               ,TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS')
                                                               ,TRUE
                                                               ,p_source_name
                                                               ,p_debug_flg
                                                               ,p_batch_size
                                                               ,ln_cust_trx_id_low
                                                               ,ln_cust_trx_id_high
                                                               ,p_gl_date_low
                                                               ,p_gl_date_high
                                                               );
              COMMIT;
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Scheduler Program');
                FND_FILE.put_line(fnd_file.log,'OD: GL COGS Interface Import '||ln_conc_request_id);
                FND_FILE.PUT_LINE(FND_FILE.LOG,'inside loop');
                FND_FILE.PUT_LINE(FND_FILE.LOG,ln_cntr);
         END IF;
                FND_FILE.PUT_LINE(FND_FILE.LOG,ln_cntr);
                FND_FILE.PUT_LINE(FND_FILE.LOG,'outside loop');
       END LOOP;
     CLOSE lcu_scheduler;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'outside cursor');
      IF ln_cntr>=1 THEN
          FND_CONC_GLOBAL.set_req_globals(conc_status =>'PAUSED',request_data=>TO_CHAR(ln_cntr));
          COMMIT;
           FND_FILE.PUT_LINE(FND_FILE.LOG,'RESTARTING COGS MASTER PROGRAM');
             x_return_message := 'Restarted COGS program';
             x_return_code    := 0;
             RETURN;
       ELSE
                     --       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_gl_date_low);
                        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'OFFICE DEPOT, INC'
                                               ||'                            '
                                               ||'OD GL COGS Report Status'
                                               ||'               '||'Report Date: '
                                               ||to_char(sysdate,'DD-MON-YYYY HH24:MI'));
                       lc_mail_subject := 'OD GL COGS Import Interface Status_';
                       lc_debug_msg    := 'Emailing output report: gn_request_id=> '
                                       ||gn_request_id || ' gc_source_name=> ' ||p_source_name
                                       || ' lc_mail_subject=> ' || lc_mail_subject;
                       DEBUG_MESSAGE (lc_debug_msg,1);
                       gc_email_lkup := p_source_name;
                       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Request ID: '|| gn_request_id);
                        XX_GL_COGS_INT_MASTER_PKG.XX_CONCAT_EMAIL_OUTPUT (p_request_id     =>gn_request_id
                                                                         ,p_email_lookup   =>p_source_name
                                                                         ,p_email_subject  =>lc_mail_subject
                                                                         );
                       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
                       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No data exists in staging table for processing raised in master program');
       END IF;
    END IF;
   END XX_GL_COGS_INT_MASTER_PROC;*/
-- +===================================================================+
-- | Name  : XX_GL_COGS_INT_MASTER_PROC                                |
-- | Description  : The procedure used to for running mulitple threads |
-- |                of COGS program                                    |
-- |                                                                   |
-- |                                                                   |
-- | Parameters :p_source_name,p_debug_flg,p_batch_size,               |
-- |             p_set_of_books_id ,p_gl_date_low,p_gl_date_high,      |
-- |             p_otc_cycle_run_date,p_otc_cycle_wave_num             |
-- |                                                                   |
-- |                                                                   |
-- | Returns :  x_return_message, x_return_code                        |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE XX_GL_COGS_INT_MASTER_PROC(
                                     x_return_message          OUT  VARCHAR2
                                    ,x_return_code             OUT  VARCHAR2
                                    ,p_source_name             IN   VARCHAR2
                                    ,p_debug_flg               IN   VARCHAR2
                                    ,p_batch_size              IN   NUMBER
                                    ,p_set_of_books_id         IN   NUMBER
                                    ,p_gl_date_low             IN   VARCHAR2
                                    ,p_gl_date_high            IN   VARCHAR2
                                    ,p_otc_cycle_run_date      IN   VARCHAR2
                                    ,p_otc_cycle_wave_num      IN   NUMBER
                                    ,p_submit_exception_report IN   VARCHAR2                      --Added for Defect 3098 on 27-APR-10
                                     )
    IS
        ln_conc_request_id         NUMBER;
        ln_parent_request_id       NUMBER := FND_GLOBAL.CONC_REQUEST_ID();
        lc_debug_msg               VARCHAR2(2000);
        ln_group_id                xx_gl_interface_na_stg.group_id%TYPE;
        ln_upper                   NUMBER;
        ln_lower                   NUMBER;
        ln_cntr                    NUMBER :=0;
        ln_cust_trx_id_low         NUMBER;
        ln_cust_trx_id_high        NUMBER;
        lc_period_start            VARCHAR2(15);
        lc_period_end              VARCHAR2(15);
        ld_actual_completion_date  DATE;
        ln_cnt_err_request         NUMBER;
        ln_concurrent_program_id   NUMBER;
        ln_program_application_id  NUMBER;
        ln_responsibility_id       NUMBER;
        ln_resp_application_id     NUMBER;
        lc_status_code             xx_gl_high_volume_jrnl_control.request_status%TYPE;
        ln_actual_completion_date  DATE;
        ln_argument_text           VARCHAR2(300);
    TYPE t_insert_scheduler IS TABLE OF VARCHAR2(1000) INDEX BY BINARY_INTEGER;
         v_insert_scheduler  t_insert_scheduler;
     CURSOR lcu_scheduler
           IS
           SELECT RAD.cust_trx_line_gl_dist_id
           FROM   ra_customer_trx_all          RTA
                 ,ra_cust_trx_line_gl_dist_all RAD
                 ,ra_customer_trx_lines_all    RAL
          WHERE  RAD.account_class        = 'REV'
--           AND    RAD.attribute_category   = 'SALES_ACCT' -- Commented by GAGARWAL on 11-Mar-2011 for SDR Changes
          AND    RAD.attribute_category   IN (  'POS','SALES_ACCT') -- Added by GAGARWAL on 11-Mar-2011 for SDR Changes
          AND    RAD.attribute6           IN ('N','E')
          AND    RAD.gl_posted_date       IS NOT NULL
          AND    RAD.set_of_books_id      = p_set_of_books_id
          AND    RAL.customer_trx_line_id =  RAD.customer_trx_line_id
          AND    RTA.customer_trx_id      =  RAL.customer_trx_id
          AND    RAD.gl_date between TO_DATE(p_gl_date_low, 'RRRR/MM/DD HH24:MI:SS') AND TO_DATE(p_gl_date_high, 'RRRR/MM/DD HH24:MI:SS')
         ORDER BY RAD.cust_trx_line_gl_dist_id;
    CURSOR lcu_conc_req (p_master_request_id IN NUMBER)
           IS
           SELECT FCR.concurrent_program_id
                 ,FCR.program_application_id
                 ,FCR.responsibility_id
                 ,FCR.responsibility_application_id
                 ,Decode(FCR.status_code,'C','Completed','G','Warning')
                 ,FCR.actual_completion_date
                 ,FCR.argument_text
           FROM   fnd_concurrent_requests FCR
                 ,fnd_concurrent_programs FCP
           WHERE  FCR.parent_request_id       = p_master_request_id
           AND    FCR.concurrent_program_id   = FCP.concurrent_program_id
           AND    FCP.concurrent_program_name = 'XX_GL_COGS_INTERFACE_CHILD';
     BEGIN
     gc_debug_flg                 := p_debug_flg;
     gc_submit_exception_report   := p_submit_exception_report;                           --Added for Defect 3098 on 27-Apr-10
              IF TO_NUMBER(NVL(FND_CONC_GLOBAL.request_data,-1)) >= 1 THEN
                           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'OFFICE DEPOT, INC'
                                                           ||'                            '
                                                           ||'OD GL COGS Report Status'
                                                           ||'               '
                                                           ||'Report Date: '
                                                           ||to_char(sysdate,'DD-MON-YYYY HH24:MI'));
                           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Request ID: '|| ln_parent_request_id);
         lc_debug_msg := 'Checking the Child Processes Errored Out';
         DEBUG_MESSAGE(lc_debug_msg);
        -------------------- Errored Requests-------------------------
        SELECT COUNT(1)
        INTO ln_cnt_err_request
        FROM fnd_concurrent_requests
        WHERE parent_request_id = ln_parent_request_id
        AND phase_code = 'C'
        AND status_code = 'E';
        IF ln_cnt_err_request <> 0 THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,ln_cnt_err_request ||' Child Programs have Errored Out.');
         x_return_code := 2;
        END IF;
-------------------------------------------------------------------------------------
----------------------Updating the xx_gl_high_volume_jrnl_control Table ------------
------------------------------------------------------------------------------------
           lc_debug_msg := 'Before Updation of xx_gl_high_volume_jrnl_control Table';
           DEBUG_MESSAGE(lc_debug_msg);
                OPEN lcu_conc_req(ln_parent_request_id);
                   LOOP
                      FETCH lcu_conc_req
                      INTO  ln_concurrent_program_id
                           ,ln_program_application_id
                           ,ln_responsibility_id
                           ,ln_resp_application_id
                           ,lc_status_code
                           ,ln_actual_completion_date
                           ,ln_argument_text
                            ;
                      EXIT WHEN lcu_conc_req%NOTFOUND;
                     UPDATE xx_gl_high_volume_jrnl_control
                     SET   concurrent_program_id             = ln_concurrent_program_id
                           ,program_application_id           = ln_program_application_id
                           ,responsibility_id                = ln_responsibility_id
                           ,responsibility_application_id    = ln_resp_application_id
                           ,request_status                   = lc_status_code
                           ,request_end_date                 = ln_actual_completion_date
                           ,request_argument_text            = ln_argument_text
                     WHERE parent_request_id                 = ln_parent_request_id;
                     COMMIT;
                    lc_debug_msg := 'xx_gl_high_volume_jrnl_control Updated Successfully ';
                    DEBUG_MESSAGE(lc_debug_msg);
                   END LOOP;
                CLOSE lcu_conc_req;
-----------------------------------------------------------------------------
------Calling the CREATE_OUTPUT Procedure to Print the Output details -------
-----------------------------------------------------------------------------
                lc_debug_msg := 'Calling Create Output To Print the Master Details';
                DEBUG_MESSAGE(lc_debug_msg);
                CREATE_OUTPUT (p_source_name               => p_source_name
                              ,p_debug_flag                => gc_debug_flg
                              ,p_batch_size                => p_batch_size
                              ,p_set_of_books_id           => p_set_of_books_id
                              ,p_gl_date_low               => p_gl_date_low
                              ,p_gl_date_high              => p_gl_date_high
                              ,p_otc_cycle_run_date        => p_otc_cycle_run_date
                              ,p_otc_cycle_wave_num        => p_otc_cycle_wave_num
                              ,p_parent_request_id         => ln_parent_request_id
                              ,p_child_request_id          => NULL
                              ,p_cust_trx_low              => NULL
                              ,p_cust_trx_high             => NULL
                              );
               lc_debug_msg := 'Master Details Output Created.';
               DEBUG_MESSAGE(lc_debug_msg);
        ---- Start of Code added for Defect 3098 on 27-APR-2010 ----
         lc_debug_msg := 'Checkin Exception Report Flag';
         DEBUG_MESSAGE(lc_debug_msg);
          IF p_submit_exception_report = 'Y'  THEN
          XX_EXCEPTION_REPORT_PROC;
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception Report Completed Successfully');
          END IF;
           ---End of Code Added for Defect 3098 on 27-APR-2010-----
         x_return_message := 'COMPLETED MASTER PROGRAM SUCCESSFULLY-EXITING';
         x_return_code    := 0;
               RETURN;
        ELSE
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Before Restart of Master program');
         FND_FILE.PUT_LINE(FND_FILE.LOG,FND_CONC_GLOBAL.request_data);
         --------------------Start Period----------------------------
         SELECT period_name
         INTO lc_period_start
         FROM gl_periods GP
         WHERE GP.period_set_name = 'OD 445 CALENDAR'
         AND TO_DATE(p_gl_date_low, 'RRRR/MM/DD HH24:MI:SS')  BETWEEN GP.start_date AND GP.end_date;
         -------------------- Period End-----------------------------
         SELECT period_name
         INTO lc_period_end
         FROM gl_periods GP
         WHERE GP.period_set_name = 'OD 445 CALENDAR'
         AND TO_DATE(p_gl_date_high, 'RRRR/MM/DD HH24:MI:SS')  BETWEEN GP.start_date AND GP.end_date;
         --------------------Checking the Period Name----------------
         lc_debug_msg := 'Checking the Period Name';
         DEBUG_MESSAGE(lc_debug_msg);
         IF (lc_period_start <> lc_period_end) THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Period Name of Both Start_Date and End_Date are Not Matching');
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Start_date Period Name: '    ||lc_period_start );
           FND_FILE.PUT_LINE(FND_FILE.LOG,'End_date Period Name: '      ||lc_period_end );
            x_return_message := 'Exiting COGS program';
            x_return_code    := 2;
            RETURN;
         END IF;
         lc_debug_msg := 'Period Name is  Checked..';
         DEBUG_MESSAGE(lc_debug_msg);
-----------------------------Submit the 'COGS INTERFACE CHILD' Program-----------------------------------
         lc_debug_msg := 'Before Submitting  COGS INTERFACE CHILD PROGRAM';
         DEBUG_MESSAGE(lc_debug_msg);
       OPEN lcu_scheduler;
       LOOP
         FETCH lcu_scheduler BULK COLLECT INTO v_insert_scheduler LIMIT P_BATCH_SIZE;
         IF (NVL(v_insert_scheduler.FIRST,0) = 0 AND  ln_cntr = 0)  THEN
            EXIT;
         ELSIF (NVL(v_insert_scheduler.FIRST,0) = 0 AND  ln_cntr > 0) THEN
             EXIT;
           ELSE
            ln_upper            := v_insert_scheduler.LAST;
            ln_lower            := v_insert_scheduler.FIRST;
            ln_cust_trx_id_low  := v_insert_scheduler(ln_lower);
            ln_cust_trx_id_high := v_insert_scheduler(ln_upper);
            ln_cntr:=ln_cntr+1;
            ln_conc_request_id :=  fnd_request.submit_request  ('XXFIN'
                                                               ,'XX_GL_COGS_INTERFACE_CHILD'
                                                               ,NULL
                                                               ,TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS')
                                                               ,TRUE
                                                               ,p_source_name
                                                               ,gc_debug_flg
                                                               ,p_batch_size
                                                               ,ln_cust_trx_id_low
                                                               ,ln_cust_trx_id_high
                                                               ,p_gl_date_low
                                                               ,p_gl_date_high
                                                               ,p_otc_cycle_run_date
                                                               ,p_otc_cycle_wave_num
                                                               );
              COMMIT;
                FND_FILE.put_line(fnd_file.log,'OD: GL COGS Interface Child '||ln_conc_request_id);
         END IF;
       END LOOP;
     CLOSE lcu_scheduler;
     lc_debug_msg := 'COGS CHILD PROGRAM Submitted  Successfully';
     DEBUG_MESSAGE(lc_debug_msg);
      IF ln_cntr>=1 THEN
          FND_CONC_GLOBAL.set_req_globals(conc_status =>'PAUSED',request_data=>TO_CHAR(ln_cntr));
          COMMIT;
           FND_FILE.PUT_LINE(FND_FILE.LOG,'RESTARTING COGS MASTER PROGRAM');
             x_return_message := 'Restarted COGS program';
             x_return_code    := 0;
             RETURN;
       END IF;
      END IF;
 END XX_GL_COGS_INT_MASTER_PROC;
--------------------------------------------------------------------------------------------------------------
--------------------Procedure Created for CR 661--------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------
-- +===================================================================+
-- | Name  :PROCESS_JRNL_LINES                                         |
-- | Description : The main processing procedure.  After records are   |
-- |               inserted in the staging table using the             |
-- |               PROCESS_JOURNALS_CHILD, you can call the            |
-- |               PROCESS_JRNL_LINES process to validate, copy        |
-- |               import the JE lines into HV GL.INTERFACE and        |
-- |               HV CONTROL tables                                   |
-- |                                                                   |
-- | Parameters : p_group_id,p_source_nm,p_err_cnt,p_debug_flag,       |
-- |              p_otc_cycle_run_date,p_otc_cycle_wave_num            |
-- |             ,p_period_name,p_parent_request_id                    |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
     PROCEDURE  PROCESS_JRNL_LINES (p_group_id             IN       NUMBER
                                   ,p_source_nm            IN       VARCHAR2
                                   ,p_debug_flag           IN       VARCHAR2
                                   ,p_otc_cycle_run_date   IN       VARCHAR2
                                   ,p_otc_cycle_wave_num   IN       NUMBER
                                   ,p_period_name          IN       VARCHAR2
                                   ,p_parent_request_id    IN       NUMBER
                                   )
     IS
            --------------------------
            -- Declare local variables
            --------------------------
            ln_group_id              NUMBER;
            lc_output_msg            VARCHAR2(2000);
            lc_debug_msg             VARCHAR2(2000);
            ln_entered_cr            XX_GL_INTERFACE_NA_STG.entered_cr%TYPE;
            ln_entered_dr            XX_GL_INTERFACE_NA_STG.entered_dr%TYPE;
            lc_error_loc             VARCHAR2(200) := NULL;
            ln_sum_cr_entered        NUMBER :=0;
            ln_sum_dr_entered        NUMBER :=0;
            ln_total_count           NUMBER :=0;
            ld_start_date            DATE          := NULL;
            lc_period_start          VARCHAR2(15);
            ln_org_id                ar_system_parameters_all.org_id%TYPE;
            ln_child_req_id          NUMBER:= FND_GLOBAL.CONC_REQUEST_ID();
            ln_set_of_books_id       NUMBER;
            lc_return_message        VARCHAR2(1000);
            lc_return_code           VARCHAR2(1000);
           BEGIN
               ---------------------
               --intialize variables
               ---------------------
               gc_debug_flg   := p_debug_flag;
              ln_set_of_books_id :=  fnd_profile.value('GL_SET_OF_BKS_ID');
                       LOG_MESSAGE          (p_grp_id    =>   p_group_id
                                            ,p_source_nm =>   p_source_nm
                                            ,p_status    =>  'VALIDATING'
                                            ,p_details   =>  'Calling update XX_VALIDATE_STG_PROC program'
                                            );
              lc_debug_msg := 'Calling XX_VALIDATE_STG_PROC to validate records ';
              DEBUG_MESSAGE(lc_debug_msg);
                       XX_VALIDATE_STG_PROC(p_group_id);
                       LOG_MESSAGE         (p_grp_id    =>   p_group_id
                                           ,p_source_nm =>   p_source_nm
                                           ,p_status    =>  'UPDATING COGS FLAG'
                                           ,p_details   =>  'Calling update COGS flag program'
                                            );
              lc_debug_msg := 'Calling UPDATE_COGS_FLAG to update COGS Generated Flag';
              DEBUG_MESSAGE(lc_debug_msg);
                       UPDATE_COGS_FLAG    (p_group_id   => p_group_id
                                           ,p_sob_id    => ln_set_of_books_id
                                           ,p_source_nm  => p_source_nm
                                           ,x_output_msg => lc_output_msg
                                            );
-------------------------------Record Check---------------------------------------------------
              lc_debug_msg := 'Check presence of records in XX_GL_INTERFACE_NA_STG Table';
              DEBUG_MESSAGE(lc_debug_msg);
                IF (gn_rec_cnt <> 0) THEN
                       SELECT org_id
                       INTO   ln_org_id
                       FROM   ar_system_parameters;
--------------------------INSERTION INTO HIGH VOLUME CONTROL TABLE ---------------------------
               lc_debug_msg := 'BEFORE INSERTION INTO xx_gl_high_volume_jrnl_control Table';
               DEBUG_MESSAGE(lc_debug_msg);
               BEGIN
                    INSERT INTO xx_gl_high_volume_jrnl_control(request_id
                                                                ,parent_request_id
                                                                ,program_short_name
                                                                ,concurrent_program_id
                                                                ,program_application_id
                                                                ,responsibility_id
                                                                ,responsibility_application_id
                                                                ,request_status
                                                                ,request_start_date
                                                                ,request_end_date
                                                                ,user_je_source_name
                                                                ,org_id
                                                                ,set_of_books_id
                                                                ,volume
                                                                ,currency
                                                                ,entered_dr
                                                                ,entered_cr
                                                                ,accounted_dr
                                                                ,accounted_cr
                                                                ,process_date
                                                                ,event_number
                                                                ,gl_interface_group_id
                                                                ,interface_status
                                                                ,journal_import_group_id
                                                                ,request_argument_text
                                                                ,creation_date
                                                                ,created_by
                                                                ,last_update_date
                                                                ,last_updated_by
                                                                ,period_name
                                                                ,hv_stg_req_id
                                                               )
                                                    SELECT   ln_child_req_id
                                                            ,p_parent_request_id
                                                            ,'XX_GL_COGS_INTERFACE_CHILD'
                                                            ,0
                                                            ,0
                                                            ,0
                                                            ,0
                                                            ,'C'
                                                            ,SYSDATE
                                                            ,SYSDATE
                                                            ,p_source_nm
                                                            ,ln_org_id
                                                            ,XGINSTG.set_of_books_id
                                                            ,COUNT(XGINSTG.group_id)
                                                            ,XGINSTG.currency_code
                                                            ,NVL(SUM(entered_dr),0)
                                                            ,NVL(SUM(entered_cr),0)
                                                            ,NVL(SUM(accounted_dr),0)
                                                            ,NVL(SUM(accounted_cr),0)
                                                            ,FND_DATE.CANONICAL_TO_DATE(p_otc_cycle_run_date)
                                                            ,p_otc_cycle_wave_num
                                                            ,XGINSTG.group_id
                                                            ,'STAGED'
                                                            ,0
                                                            ,'COGS,N,...'
                                                            ,SYSDATE
                                                            ,FND_GLOBAL.USER_ID
                                                            ,SYSDATE
                                                            ,FND_GLOBAL.USER_ID
                                                            ,p_period_name
                                                            ,ln_child_req_id
                                                    FROM  xx_gl_interface_na_stg    XGINSTG
                                                    WHERE XGINSTG.user_je_source_name   = p_source_nm
                                                    AND   XGINSTG.group_id              = p_group_id
                                                    AND   XGINSTG.set_of_books_id       = ln_set_of_books_id
                                                    GROUP BY ln_child_req_id
                                                            ,p_parent_request_id
                                                            ,'XX_GL_COGS_INTERFACE_CHILD'
                                                            ,0
                                                            ,0
                                                            ,0
                                                            ,0
                                                            ,'C'
                                                            ,SYSDATE
                                                            ,SYSDATE
                                                            ,p_source_nm
                                                            ,ln_org_id
                                                            ,XGINSTG.set_of_books_id
                                                            ,XGINSTG.currency_code
                                                            ,FND_DATE.CANONICAL_TO_DATE(p_otc_cycle_run_date)
                                                            ,p_otc_cycle_wave_num, XGINSTG.group_id
                                                            ,'STAGED'
                                                            ,0
                                                            ,'COGS,N,...'
                                                            ,SYSDATE
                                                            ,FND_GLOBAL.USER_ID
                                                            ,SYSDATE
                                                            ,FND_GLOBAL.USER_ID
                                                            ,p_period_name
                                                            ,ln_child_req_id
                                                             ;
                   lc_error_loc := 'Fetching the count of tracking records inserted';
                   lc_debug_msg := 'INSERTION INTO xx_gl_high_volume_jrnl_control Table is Successful';
                   DEBUG_MESSAGE(lc_debug_msg);
               EXCEPTION
               WHEN OTHERS THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_loc);
               FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||'--'||SQLERRM);
               END;
---------------------INSERT INTO HIGH VOLUME NA STAGIN TABLE (XX_AR_GL_TRANSFER_PKG)--------------------------
                 lc_debug_msg := 'BEFORE INSERTION INTO xx_gl_interface_high_vol_na Table ';
                 DEBUG_MESSAGE(lc_debug_msg);
               BEGIN
                 INSERT INTO xx_gl_interface_high_vol_na    
                                         (status
                                         ,set_of_books_id
                                         ,accounting_date
                                         ,currency_code
                                         ,date_created
                                         ,created_by
                                         ,actual_flag
                                         ,user_je_category_name
                                         ,user_je_source_name
                                         ,currency_conversion_date
                                         ,encumbrance_type_id
                                         ,budget_version_id
                                         ,user_currency_conversion_TYPE
                                         ,currency_conversion_rate
                                         ,average_journal_flag
                                         ,originating_bal_seg_value
                                         ,segment1
                                         ,segment2
                                         ,segment3
                                         ,segment4
                                         ,segment5
                                         ,segment6
                                         ,segment7
                                         ,segment8
                                         ,segment9
                                         ,segment10
                                         ,segment11
                                         ,segment12
                                         ,segment13
                                         ,segment14
                                         ,segment15
                                         ,segment16
                                         ,segment17
                                         ,segment18
                                         ,segment19
                                         ,segment20
                                         ,segment21
                                         ,segment22
                                         ,segment23
                                         ,segment24
                                         ,segment25
                                         ,segment26
                                         ,segment27
                                         ,segment28
                                         ,segment29
                                         ,segment30
                                         ,entered_dr
                                         ,entered_cr
                                         ,accounted_dr
                                         ,accounted_cr
                                         ,transaction_date
                                         ,reference1
                                         ,reference2
                                         ,reference3
                                         ,reference4
                                         ,reference5
                                         ,reference6
                                         ,reference7
                                         ,reference8
                                         ,reference9
                                         ,reference10
                                         ,reference11
                                         ,reference12
                                         ,reference13
                                         ,reference14
                                         ,reference15
                                         ,reference16
                                         ,reference17
                                         ,reference18
                                         ,reference19
                                         ,reference20
                                         ,reference21
                                         ,reference22
                                         ,reference23
                                         ,reference24
                                         ,reference25
                                         ,reference26
                                         ,reference27
                                         ,reference28
                                         ,reference29
                                         ,reference30
                                         ,je_batch_id
                                         ,period_name
                                         ,je_header_id
                                         ,je_line_num
                                         ,chart_of_accounts_id
                                         ,functional_currency_code
                                         ,code_combination_id
                                         ,date_created_in_gl
                                         ,warning_code
                                         ,status_description
                                         ,stat_amount
                                         ,group_id
                                         ,request_id
                                         ,subledger_doc_sequence_id
                                         ,subledger_doc_sequence_vaLUE
                                         ,attribute1
                                         ,attribute2
                                         ,gl_sl_link_id
                                         ,gl_sl_link_table
                                         ,attribute3
                                         ,attribute4
                                         ,attribute5
                                         ,attribute6
                                         ,attribute7
                                         ,attribute8
                                         ,attribute9
                                         ,attribute10
                                         ,attribute11
                                         ,attribute12
                                         ,attribute13
                                         ,attribute14
                                         ,attribute15
                                         ,attribute16
                                         ,attribute17
                                         ,attribute18
                                         ,attribute19
                                         ,attribute20
                                         ,context
                                         ,context2
                                         ,invoice_date
                                         ,tax_code
                                         ,invoice_identifier
                                         ,invoice_amount
                                         ,context3
                                         ,ussgl_transaction_code
                                         ,descr_flex_error_message
                                         ,jgzz_recon_ref
                                         ,reference_date
                                         )
                               SELECT     'STAGED'
                                         ,set_of_books_id
                                         ,accounting_date
                                         ,currency_code
                                         ,date_created
                                         ,created_by
                                         ,actual_flag
                                         ,user_je_category_name
                                         ,user_je_source_name
                                         ,currency_conversion_date
                                         ,encumbrance_type_id
                                         ,budget_version_id
                                         ,user_currency_conversion_TYPE
                                         ,currency_conversion_rate
                                         ,average_journal_flag
                                         ,originating_bal_seg_value
                                         ,segment1
                                         ,segment2
                                         ,segment3
                                         ,segment4
                                         ,segment5
                                         ,segment6
                                         ,segment7
                                         ,segment8
                                         ,segment9
                                         ,segment10
                                         ,segment11
                                         ,segment12
                                         ,segment13
                                         ,segment14
                                         ,segment15
                                         ,segment16
                                         ,segment17
                                         ,segment18
                                         ,segment19
                                         ,segment20
                                         ,segment21
                                         ,segment22
                                         ,segment23
                                         ,segment24
                                         ,segment25
                                         ,segment26
                                         ,segment27
                                         ,segment28
                                         ,segment29
                                         ,segment30
                                         ,entered_dr
                                         ,entered_cr
                                         ,accounted_dr
                                         ,accounted_cr
                                         ,transaction_date
                                         ,reference1
                                         ,reference2
                                         ,reference3
                                         ,reference4
                                         ,reference5
                                         ,reference6
                                         ,reference7
                                         ,reference8
                                         ,reference9
                                         ,reference10
                                         ,reference11
                                         ,reference12
                                         ,reference13
                                         ,reference14
                                         ,reference15
                                         ,reference16
                                         ,reference17
                                         ,reference18
                                         ,reference19
                                         ,reference20
                                         ,attribute11
                                         ,attribute12
                                         ,attribute13
                                         ,attribute14
                                         ,attribute15
                                         ,attribute16
                                         ,(segment1||'.'||segment2||'.'||segment3||'.'||segment4||'.'||segment5||'.'||segment6||'.'||segment7||','||entered_dr||','||entered_cr||','||attribute10||','||reference27)   --- added for defect 8261
                                         ,attribute18
                                         ,attribute19
                                         ,attribute20
                                         ,je_batch_id
                                         ,period_name
                                         ,je_header_id
                                         ,je_line_num
                                         ,chart_of_accounts_id
                                         ,functional_currency_code
                                         ,code_combination_id
                                         ,date_created_in_gl
                                         ,warning_code
                                         ,status_description
                                         ,stat_amount
                                         ,group_id
                                         ,ln_child_req_id
                                         ,subledger_doc_sequence_id
                                         ,subledger_doc_sequence_vaLUE
                                         ,attribute1
                                         ,attribute2
                                         ,gl_sl_link_id
                                         ,gl_sl_link_table
                                         ,attribute3
                                         ,attribute4
                                         ,attribute5
                                         ,attribute6
                                         ,attribute7
                                         ,attribute8
                                         ,attribute9
                                         ,attribute10
                                         ,attribute11
                                         ,attribute12
                                         ,attribute13
                                         ,attribute14
                                         ,attribute15
                                         ,attribute16
                                         ,attribute17
                                         ,attribute18
                                         ,attribute19
                                         ,attribute20
                                         ,context
                                         ,context2
                                         ,invoice_date
                                         ,tax_code
                                         ,invoice_identifier
                                         ,invoice_amount
                                         ,context3
                                         ,ussgl_transaction_code
                                         ,descr_flex_error_message
                                         ,jgzz_recon_ref
                                         ,reference_date
                               FROM  xx_gl_interface_na_stg
                               WHERE user_je_source_name = p_source_nm
                               AND   group_id            = p_group_id
                               AND   set_of_books_id     = ln_set_of_books_id;
                 lc_debug_msg := ' INSERTION INTO xx_gl_interface_high_vol_na Table is Successful ';
                 DEBUG_MESSAGE(lc_debug_msg);
               EXCEPTION
               WHEN OTHERS THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_loc);
               FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||'--'||SQLERRM);
               END;
                                   --------------------------------------------
                    ---Delete based on  group_id and sob id-----
                    --------------------------------------------
                lc_debug_msg := ' Before Deletion of Records in xx_gl_interface_na_stg ';
                DEBUG_MESSAGE(lc_debug_msg);
              BEGIN
                   DELETE FROM xx_gl_interface_na_stg
                   WHERE  group_id        = p_group_id
                   AND    set_of_books_id = ln_set_of_books_id
                   AND    user_je_source_name = p_source_nm ;
                   lc_debug_msg := ' Deleted records from'
                                 ||' staging table for group_id: '
                                 || p_group_id
                                 ||' and set of books id => '
                                 ||ln_set_of_books_id ;
                   DEBUG_MESSAGE (lc_debug_msg);
               EXCEPTION
                   WHEN OTHERS THEN
                       FND_MESSAGE.CLEAR();
                       FND_MESSAGE.SET_NAME('FND','FS-UNKNOWN');
                       FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
                   FND_FILE.PUT_LINE(FND_FILE.LOG,'ERROR in: '
                                         ||fnd_message.get()
                                     );
               END;
          END IF;--- Record Count
      END PROCESS_JRNL_LINES;
---------------------------------------------------------------------------------------------
----------------Procedures from XX_GL_INTERFACE_NA_STG Package Added for CR 661--------------
---------------------------------------------------------------------------------------------
-- +===================================================================+
-- | Name         :DEBUG_MESSAGE                                       |
-- | Description  :  This local procedure will write debug state-      |
-- |                     ments to the log file if debug_flag is Y      |
-- |                                                                   |
-- | Parameters   :p_message (msg written), p_spaces (# of blank lines)|
-- |                                                                   |
-- +===================================================================+
    PROCEDURE DEBUG_MESSAGE (p_message  IN  VARCHAR2
                            ,p_spaces   IN  NUMBER  DEFAULT 0 )
    IS
    ln_space_cnt NUMBER := 0;
    BEGIN
         IF gc_debug_flg = 'Y' THEN
               LOOP
               EXIT WHEN ln_space_cnt = p_spaces;
                    FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
                    ln_space_cnt := ln_space_cnt + 1;
               END LOOP;
               FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);
         END IF;
   END DEBUG_MESSAGE;
-- +===================================================================+
-- | Name        :LOG_MESSAGE                                          |
-- | Description :  This procedure will be used to write record to the |
-- |                xx_gl_interface_na_log table.                      |
-- |                                                                   |
-- | Parameters  : p_grp_id,p_source_nm,p_status,p_details,p_debug_flag|
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE  LOG_MESSAGE (p_grp_id         IN NUMBER   DEFAULT NULL
                           ,p_source_nm      IN VARCHAR2 DEFAULT NULL
                           ,p_status         IN VARCHAR2 DEFAULT NULL
                           ,p_details        IN VARCHAR2 DEFAULT NULL
                           ,p_debug_flag     IN VARCHAR2 DEFAULT NULL
                            )
     IS
           lc_debug_prog     VARCHAR2(12) := 'LOG_MESSAGE';
           ln_request_id     NUMBER := FND_GLOBAL.CONC_REQUEST_ID();
           x_output_msg      VARCHAR2(2000);
           lc_debug_msg      VARCHAR2(2000);
           lc_date           VARCHAR2(25);
     BEGIN
           IF p_debug_flag IS NOT NULL THEN
                 gc_debug_flg := p_debug_flag;
           END IF;
            SELECT to_char(sysdate,'DD-MON-YYYY HH24:MI:SS')
            INTO lc_date
            FROM DUAL;
          lc_debug_msg     :=  'Inside log message'
                             ||'  '
                             ||' status       => '|| p_status
                             ||'  '
                             ||' details      => '|| p_details;
           DEBUG_MESSAGE (lc_debug_msg);
            BEGIN
                 IF p_debug_flag = 'Y' THEN
                   INSERT INTO xx_gl_interface_na_log
                           (group_id
                           ,source_name
                           ,status
                           ,request_id
                           ,date_time
                           ,details)
                    VALUES
                          (p_grp_id
                          ,p_source_nm
                          ,p_status
                          ,ln_request_id
                          ,lc_date
                          ,p_details );
                  END IF;
            END;
            EXCEPTION
            WHEN OTHERS THEN
               x_output_msg  := 'insert into log file'|| SQLERRM;
               FND_MESSAGE.SET_NAME('FND','FS-UNKNOWN');
                lc_debug_msg := fnd_message.get();
                DEBUG_MESSAGE  (lc_debug_msg);
                FND_FILE.PUT_LINE(FND_FILE.LOG, lc_debug_msg );
    END LOG_MESSAGE;
-- +===================================================================+
-- | Name         :XX_VALIDATE_STG_PROC                                |
-- | Description  :  This Procedure will validate the records          |
-- |                   which will be fetched  from the AR tables       |
-- | Parameters   : p_group_id                                         |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE XX_VALIDATE_STG_PROC(p_group_id IN NUMBER)
    IS
       BEGIN
         UPDATE xx_gl_interface_na_stg STG
         SET   STG.derived_val='INVALID'
         WHERE STG.group_id =p_group_id
         AND (STG.reference25 IS NULL or STG.reference26 IS NULL or STG.reference27 IS NULL);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'No of rows updated with Invalid Status'||'  '||'is'||'   '||sql%rowcount);
        -- COMMIT;
         EXCEPTION
        WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others exception raised'||sqlerrm);
    END XX_VALIDATE_STG_PROC;
-- +===================================================================+
-- | Name  :    UPDATE_COGS_FLAG                                       |
-- | Description   :This Procedure will update the COGS Generated Flag |
-- |                       for valid COGS journal entries              |
-- |                                                                   |
-- | Parameters :    p_group_id,p_sob_id,p_source_nm                   |
-- |                                                                   |
-- |                                                                   |
-- | Returns :       x_output_msg                                      |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE UPDATE_COGS_FLAG (p_group_id   IN NUMBER
                               ,p_sob_id     IN NUMBER
                               ,p_source_nm  IN VARCHAR2
                               ,x_output_msg OUT VARCHAR2
                               )
    IS
       lc_debug_msg  VARCHAR(1000);
       ln_v_dr_amt   NUMBER        :=0;
       ln_v_cr_amt   NUMBER        :=0;
       ln_in_dr_amt  NUMBER        :=0;
       ln_in_cr_amt  NUMBER        :=0;
       ln_del_rec    NUMBER        :=0;
/*start of changes for the defect 3098*/
        CURSOR lcu_update
           IS
            SELECT   STG.code_combination_id
                    ,STG.reference21
                    ,STG.segment1
                    ,STG.segment2
                    ,STG.segment3
                    ,STG.segment4
                    ,STG.segment5
                    ,STG.segment6
                    ,STG.segment7
            FROM xx_gl_interface_na_stg   STG
            WHERE STG.code_combination_id = 0
            AND STG.group_id               = p_group_id
            AND STG.user_je_source_name    = p_source_nm
            AND STG.set_of_books_id        = p_sob_id;
     BEGIN
          UPDATE /*+ index(RAD RA_CUST_TRX_LINE_GL_DIST_U1) */
                 ra_cust_trx_line_gl_dist_all RAD
            SET RAD.attribute6 = 'Y'
                ,RAD.attribute12 = NULL
            WHERE RAD.cust_trx_line_gl_dist_id IN
            (SELECT TO_NUMBER(STG.reference21)
               FROM xx_gl_interface_na_stg stg
               WHERE STG.group_id = p_group_id
               AND STG.user_je_source_name = p_source_nm
               AND STG.derived_val = 'VALID'
               AND STG.derived_sob = 'VALID'
               AND STG.balanced = 'BALANCED');

             UPDATE /*+ index(RAD RA_CUST_TRX_LINE_GL_DIST_U1) */
                    ra_cust_trx_line_gl_dist_all RAD
             SET    RAD.attribute6 = 'E'
                   ,RAD.attribute12 = 'Either COGS Account or Inventory/Liability Account or Average Item Cost is NULL'
             WHERE  RAD.cust_trx_line_gl_dist_id in
/* Start of changes for the defect 5494 on 21-JUL-10 for addition of parenthesis in the OR clause */

               /*(SELECT to_number(STG.reference21)
                 FROM   xx_gl_interface_na_STG STG
                 WHERE  STG.group_id               = p_group_id
                 AND    STG.user_je_source_name    = p_source_nm
                 AND    STG.derived_val            = 'INVALID'
                 AND    STG.reference25              IS NULL
                 OR     STG.reference26              IS NULL
                 OR     STG.reference27              IS NULL );*/

               (SELECT TO_NUMBER(STG.reference21)
                 FROM   xx_gl_interface_na_STG STG
                 WHERE  STG.group_id               = p_group_id
                 AND    STG.user_je_source_name    = p_source_nm
                 AND    STG.derived_val            = 'INVALID'
                 AND    (STG.reference25              IS NULL
                 OR     STG.reference26              IS NULL
                 OR     STG.reference27              IS NULL ));
/* End of changes for the defect 5494 on 21-JUL-10 */

            FOR cnt IN lcu_update
            LOOP
                 UPDATE xx_gl_interface_na_stg STG
                 SET   STG.derived_val  ='INVALID'
                 WHERE STG.reference21          = TO_NUMBER(cnt.reference21)
                 AND   STG.group_id             = p_group_id
                 AND   STG.user_je_source_name  = p_source_nm;
                 UPDATE /*+ index(RAD RA_CUST_TRX_LINE_GL_DIST_U1) */
                      ra_cust_trx_line_gl_dist_all RAD
                 SET    RAD.attribute6 = 'E'
                       ,RAD.attribute12 = 'Unable to derive CCID for the segments - ' ||cnt.segment1||'.'||cnt.segment2||'.'||cnt.segment3||'.'||cnt.segment4||'.'||cnt.segment5||'.'||cnt.segment6||'.'||cnt.segment7
                 WHERE  RAD.cust_trx_line_gl_dist_id  = TO_NUMBER(cnt.reference21);
            END LOOP;
/*End of changes for the defect 3098*/

/* Start of changes for the Defect #5494  on 21-JUL-10 for addition of parenthesis in the OR clause*/

          /* SELECT
                SUM(entered_dr)
               ,SUM(entered_cr)
             INTO
               ln_in_dr_amt
              ,ln_in_cr_amt
             FROM  xx_gl_interface_na_STG
             WHERE group_id=p_group_id
             AND   derived_val         = 'INVALID'
             OR    derived_sob         = 'INVALID'
             OR    balanced            = 'UNBALANCED'; */

             SELECT
                SUM(entered_dr)
               ,SUM(entered_cr)
             INTO
               ln_in_dr_amt
              ,ln_in_cr_amt
             FROM  xx_gl_interface_na_STG
             WHERE group_id=p_group_id
             AND  (derived_val        = 'INVALID'
             OR    derived_sob         = 'INVALID'
             OR    balanced            = 'UNBALANCED'); 
/* End of changes for the Defect #5494 on 21-JUL-10*/

            FND_FILE.PUT_LINE(FND_FILE.LOG,'Sum of Entered Debit  (Invalid records)'
                                           ||' is : '
                                           ||ln_in_dr_amt);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Sum of Entered Credit (Invalid records)'
                                          ||' is : '
                                          ||ln_in_cr_amt);
            SELECT
                SUM(entered_dr)
               ,SUM(entered_cr)
            INTO
               ln_v_dr_amt
              ,ln_v_cr_amt
            FROM xx_gl_interface_na_STG
            WHERE group_id=p_group_id
            AND  derived_val         = 'VALID'
            AND derived_sob          = 'VALID'
            AND balanced             = 'BALANCED';
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Sum of Entered Debit (valid records) '
                                           ||' is : '
                                           ||ln_v_dr_amt);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Sum of Entered Credit (valid records)'
                                           ||' is : '
                                           ||ln_v_cr_amt);
           IF p_source_nm='OD COGS' THEN

/* Start of changes for the Defect #5494 on 21-JUL-10 for addition of parenthesis in the OR clause*/

            /* DELETE FROM  xx_gl_interface_na_STG
               WHERE group_id          = p_group_id
               AND set_of_books_id     = p_sob_id
               AND derived_val         = 'INVALID'
               OR derived_sob          = 'INVALID'
               OR balanced             = 'UNBALANCED'; */ 

               DELETE FROM  xx_gl_interface_na_STG
               WHERE group_id          = p_group_id
               AND set_of_books_id     = p_sob_id
               AND (derived_val         = 'INVALID'
               OR derived_sob          = 'INVALID'
               OR balanced             = 'UNBALANCED');
/* End of changes for the Defect #5494 on 21-JUL-10 */

               ln_del_rec :=sql%rowcount;

               FND_FILE.PUT_LINE(FND_FILE.LOG,'No Of COGS records deleted'
                                             ||' is : '
                                             ||ln_del_rec);
            END IF;
              lc_debug_msg := 'Completed UPDATE_COGS_FLAG';
              DEBUG_MESSAGE  (lc_debug_msg);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Checkin Invalid CCID');
    EXCEPTION
      WHEN OTHERS then
         FND_MESSAGE.SET_NAME('FND','FS-UNKNOWN');
         FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
          x_output_msg := fnd_message.get;
     END UPDATE_COGS_FLAG;
-- +===========================================================================+
-- | Name  :       CREATE_OUTPUT                                               |
-- | Description  :This Procedure will Print the Output for the Master         |
-- |               and Child Program                                           |
-- |                                                                           |
-- | Parameters :    p_source_name,p_debug_flag,p_batch_size,                  |
-- |                ,p_set_of_books_id,p_gl_date_low,p_gl_date_high,           |
-- |                ,p_otc_cycle_run_date,p_otc_cycle_wave_num                 |
-- |                ,p_parent_request_id ,p_cust_trx_low,p_cust_trx_high       |
-- +===========================================================================+
      PROCEDURE  CREATE_OUTPUT (p_source_name             IN   VARCHAR2
                               ,p_debug_flag              IN   VARCHAR2
                               ,p_batch_size              IN   NUMBER
                               ,p_set_of_books_id         IN   NUMBER
                               ,p_gl_date_low             IN   VARCHAR2
                               ,p_gl_date_high            IN   VARCHAR2
                               ,p_otc_cycle_run_date      IN   VARCHAR2
                               ,p_otc_cycle_wave_num      IN   NUMBER
                               ,p_parent_request_id       IN   NUMBER
                               ,p_child_request_id        IN   NUMBER
                               ,p_cust_trx_low            IN   NUMBER
                               ,p_cust_trx_high           IN   NUMBER
                              )
          IS
              lc_status_code            fnd_concurrent_requests.status_code%TYPE                := NULL;
              lc_status_code_stg        fnd_concurrent_requests.status_code%TYPE                := NULL;
              ln_sum_cr_entered         NUMBER                                                  := 0;
              ln_sum_dr_entered         NUMBER                                                  := 0;
              ln_total_count            NUMBER                                                  := 0;
              lc_chk_flag               VARCHAR2(120)                                           := NULL;
              lc_space                  VARCHAR2(3)                                             := ' ';
-------------------------------------------------------------------------------------------------------
-------------- To get the Details of CHild Processes Submitted and  Status of the Interfaces-----------
-------------------------------------------------------------------------------------------------------
           CURSOR lcu_cntrl_info_summary
               IS
                  SELECT XGHVJC.parent_request_id
                        ,XGHVJC.request_id
                        ,FCRSV.user_concurrent_program_name
                        ,XGHVJC.gl_interface_group_id
                        ,DECODE(phase_code
                              ,'C', 'Completed'
                              ,'I', 'Inactive'
                              ,'P', 'Pending'
                              ,'R', 'Running'
                                )                       phase_code
                        ,DECODE(status_code
                              ,'C','Normal'
                              ,'X','Terminated'
                              ,'G','Warning'
                              ,'W','Paused'
                              ,'E','Error'
                                )                        status_code
                        ,XGHVJC.volume
                        ,XGHVJC.entered_dr
                        ,XGHVJC.entered_cr
                        ,XGHVJC.currency
                        ,XGHVJC.interface_status
                   FROM xx_gl_high_volume_jrnl_control XGHVJC
                       ,fnd_conc_req_summary_v FCRSV
                  WHERE XGHVJC.parent_request_id = NVL(p_parent_request_id,XGHVJC.parent_request_id)
                  AND XGHVJC.request_id          = NVL(p_child_request_id,XGHVJC.request_id)
                  AND XGHVJC.request_id          = FCRSV.request_id;
          ltab_cntrl_summ_rec      lcu_cntrl_info_summary%ROWTYPE;
BEGIN
 --------------------------
--  Output Section --Starts
---------------------------
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('Office Depot',50,lc_space));--||LPAD('Date : '||TO_CHAR(SYSDATE, 'DD-MON-YYYY'),135,lc_space));
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('Date',30,lc_space));
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('Request ID',50,lc_space));
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('Page',50,lc_space));
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
             IF  p_child_request_id IS  NULL THEN
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                                OD: GL Inteface for COGS Master                                  ');
             ELSE
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                                OD COGS CHILD                                  ');
             END IF;
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Source Name                : '||p_source_name);
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Batch Size                 : '||p_batch_size);
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Debug Flag                 : '||p_debug_flag);
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'GL Date Low                : '||p_gl_date_low);
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'GL Date High               : '||p_gl_date_high);
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Set of Books               : '||p_set_of_books_id);
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Cycle Date                 : '||p_otc_cycle_run_date);
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'OTC Wave#                  : '||p_otc_cycle_wave_num);
             ----Start ofCode Added for Defect 3098 on 27-APR-10 --------
             IF  p_child_request_id IS  NULL THEN
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Submit Exception Report    : '||gc_submit_exception_report);
             END IF;
             ---End of Code Added for Defect 3098 on 27-APR-10 ----------
             IF p_child_request_id IS NOT NULL THEN
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Customer TRX ID LOW     : '||p_cust_trx_low);
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Customer TRX ID HIGH    : '||p_cust_trx_high);
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Parent_request_id       : '||p_parent_request_id);
             END IF;
            ---Start ofCode Added for Defect 3098 on 28-APR-10----------
-- Child Process Submitted
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
             IF  p_child_request_id IS  NULL THEN
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Child Process Submitted');
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(lc_space,81,'-'));
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('Req ID',15)||RPAD('Concurrent Program Name',37)||RPAD('Phase',14)||RPAD('Status',15));
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(lc_space,81,'-'));
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
                OPEN lcu_cntrl_info_summary;
                  LOOP
                  FETCH lcu_cntrl_info_summary INTO ltab_cntrl_summ_rec;
                  EXIT WHEN lcu_cntrl_info_summary%NOTFOUND;
                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(ltab_cntrl_summ_rec.request_id,15)||RPAD(ltab_cntrl_summ_rec.user_concurrent_program_name,37)||RPAD(ltab_cntrl_summ_rec.phase_code,14)||RPAD(ltab_cntrl_summ_rec.status_code,15));
                  END LOOP;
                CLOSE lcu_cntrl_info_summary;
             END IF;
-- Status of Interfaces
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Status of Interfaces');
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'  '||RPAD(lc_space,185,'-'));
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'  '||RPAD('Parent Request ID',22)||RPAD('Child Request id',22)||RPAD('Program Name',37)||RPAD('Group ID',18)||RPAD('Count',20)||RPAD('Entered DR',21)||RPAD('Entered CR',21)||RPAD('Currency',12)||RPAD('Status',12));
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'  '||RPAD(lc_space,185,'-'));
             OPEN lcu_cntrl_info_summary;
               LOOP
                FETCH lcu_cntrl_info_summary INTO ltab_cntrl_summ_rec;
                EXIT WHEN lcu_cntrl_info_summary%NOTFOUND;
                ln_sum_dr_entered := ln_sum_dr_entered + ltab_cntrl_summ_rec.entered_dr;
                ln_sum_cr_entered := ln_sum_cr_entered + ltab_cntrl_summ_rec.entered_cr;
                ln_total_count := ln_total_count + ltab_cntrl_summ_rec.volume;
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'  '||RPAD(ltab_cntrl_summ_rec.parent_request_id,22)
                                                      ||RPAD(ltab_cntrl_summ_rec.request_id,22)
                                                      ||RPAD(ltab_cntrl_summ_rec.user_concurrent_program_name,37)
                                                      ||RPAD(ltab_cntrl_summ_rec.gl_interface_group_id,18)
                                                      ||RPAD(ltab_cntrl_summ_rec.volume,20)
                                                      ||RPAD(ltab_cntrl_summ_rec.entered_dr,21)
                                                      ||RPAD(ltab_cntrl_summ_rec.entered_cr,21)
                                                      ||RPAD(ltab_cntrl_summ_rec.currency,12)
                                                      ||RPAD(ltab_cntrl_summ_rec.interface_status,12)
                                     );
               END LOOP;
             CLOSE lcu_cntrl_info_summary;
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(lc_space,100)||RPAD(lc_space,62,'-')||RPAD(lc_space,24));
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(lc_space,101)||RPAD(ln_total_count,20)||RPAD(ln_sum_dr_entered,21)||RPAD(ln_sum_cr_entered,21));
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(lc_space,100)||RPAD(lc_space,62,'-')||RPAD(lc_space,24));
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD('*** End of Report ***',70));
-------------------------
-- Output Section -- Ends
--------------------------
END CREATE_OUTPUT;
-- +===================================================================+-------Procedure Added as part of Defect #3098 on 27-APR-10
-- | Name  :XX_EXCEPTION_REPORT_PROC                                   |
-- | Description      :  This Procedure will Submit request for the    |
-- |                     Report which will fetch  the  Invalid records |
-- |                     from the staging table                        |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE XX_EXCEPTION_REPORT_PROC
    IS
    lc_phase                    VARCHAR2(50);
    lc_status                   VARCHAR2(50);
    lc_temp_email               VARCHAR2(250);
    lc_devphase                 VARCHAR2(50);
    lc_devstatus                VARCHAR2(50);
    lc_message                  VARCHAR2(250);
    lb_req_status               BOOLEAN;
    ln_request_id               fnd_concurrent_requests.request_id%TYPE;
    lb_set_layout_option        BOOLEAN;
    lc_debug_msg                VARCHAR2(1000);
    ln_conc_id                  fnd_concurrent_requests.request_id%TYPE;
    lc_translate_name           VARCHAR2(19)   :='GL_INTERFACE_EMAIL';
    lc_first_rec                VARCHAR(1);
    lc_output_file              VARCHAR2(50);
    lc_file_extension           VARCHAR2(10);
    p_org_id                    NUMBER;
    TYPE TYPE_TAB_EMAIL IS TABLE OF
                 XX_FIN_TRANSLATEVALUES.target_value1%TYPE INDEX
                 BY BINARY_INTEGER ;
    EMAIL_TBL TYPE_TAB_EMAIL;
   BEGIN
     p_org_id := fnd_profile.value('ORG_ID');
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Org Id is ' ||  p_org_id);
----------------- To Fetch the Email Address to Which The Exception Report Need to be Send ---------
           BEGIN
                  SELECT TV.target_value1
                        ,TV.target_value2
                        ,TV.target_value3
                        ,TV.target_value4
                        ,TV.target_value5
                        ,TV.target_value6
                        ,TV.target_value7
                  INTO   EMAIL_TBL(1)
                        ,EMAIL_TBL(2)
                        ,EMAIL_TBL(3)
                        ,EMAIL_TBL(4)
                        ,EMAIL_TBL(5)
                        ,EMAIL_TBL(6)
                        ,EMAIL_TBL(7)
                  FROM   XX_FIN_TRANSLATEVALUES TV
                        ,XX_FIN_TRANSLATEDEFINITION TD
                  WHERE TV.TRANSLATE_ID  = TD.TRANSLATE_ID
                  AND   TRANSLATION_NAME = lc_translate_name
                  AND   source_value1    = 'OD COGS';
                 lc_first_rec  := 'Y';
                 FOR ln_cnt IN 1..7 LOOP
                      IF EMAIL_TBL(ln_cnt) IS NOT NULL THEN
                           IF lc_first_rec = 'Y' THEN
                               lc_temp_email := EMAIL_TBL(ln_cnt);
                               lc_first_rec := 'N';
                           ELSE
                               lc_temp_email :=  lc_temp_email ||' : ' || EMAIL_TBL(ln_cnt);
                           END IF;
                      END IF;
                 END LOOP ;
           EXCEPTION
           WHEN OTHERS THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG, 'Exception raised while fetching Email Address to send the Excel Output for'
                 ||'the Exception Report');
           END;
            lb_set_layout_option := FND_REQUEST.ADD_LAYOUT(
                                                          template_appl_name => 'XXFIN',
                                                          template_code      => 'XXGLCOGSEXC',
                                                          template_language  => 'en',
                                                          template_territory => 'US',
                                                          output_format      => 'EXCEL');
            ln_request_id := FND_REQUEST.SUBMIT_REQUEST(
                                                        application => 'XXFIN'
                                                        ,program     => 'XXGLCOGSEXC'
                                                        ,description => 'OD: GL COGS Journal Exception Report '
                                                        ,start_time  => NULL
                                                        ,sub_request => FALSE
                                                        ,argument1   => p_org_id  
                                                       );
           COMMIT;
        IF ln_request_id = 0   THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG,'Error : OD: GL COGS Journal Exception Report Not Submitted');
        ELSE
            FND_FILE.PUT_LINE (FND_FILE.LOG,'Submitted request '|| TO_CHAR (ln_request_id)||'  '||'OD: GL  COGS Journal Exception Report');
            lb_req_status := FND_CONCURRENT.WAIT_FOR_REQUEST (
                                                              request_id => ln_request_id
                                                             ,interval   => '10'
                                                             ,max_wait   => ''
                                                             ,phase      => lc_phase
                                                             ,status     => lc_status
                                                             ,dev_phase  => lc_devphase
                                                             ,dev_status => lc_devstatus
                                                             ,message    => lc_message
                                                            );
            IF    (lc_devstatus !='NORMAL_STATUS')
            AND   (lc_devphase   = 'COMPLETE_PHASE')     THEN
               FND_FILE.PUT_LINE (FND_FILE.LOG,'Warning: Failed to OD: GL  COGS Journal Exception Report Program ');
            ELSE
           lc_output_file    := 'XXGLCOGSEXC_'||ln_request_id||'_1'||'.EXCEL';
           lc_file_extension := '.xls';
           ln_conc_id        := FND_REQUEST.SUBMIT_REQUEST(
                                                         application => 'XXFIN'
                                                        ,program     => 'XXODROEMAILERCOGSPROG'
                                                        ,description => NULL
                                                        ,start_time  => SYSDATE
                                                        ,sub_request => FALSE
                                                        ,argument1   => NULL
                                                        ,argument2   => lc_temp_email
                                                        ,argument3   => 'OD_COGS_Exception_report'
                                                        ,argument4   => NULL
                                                        ,argument5   => 'Y'
                                                        ,argument6   => ln_request_id
                                                        ,argument7   => lc_output_file
                                                        ,argument8   => lc_file_extension
                                                       );
           END IF;
       END IF;
   EXCEPTION
         WHEN OTHERS THEN
             fnd_message.set_name('FND','FS-UNKNOWN');
             fnd_message.set_token('ERROR',SQLERRM);
             lc_debug_msg := fnd_message.get();
             DEBUG_MESSAGE  (lc_debug_msg);
             FND_FILE.PUT_LINE(FND_FILE.LOG, lc_debug_msg );
   END  XX_EXCEPTION_REPORT_PROC;
---------------------------------------------------------------------------------------------------------
----------------Functions Added for CR 661---------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
-- +===================================================================+
-- | Name          : GET_CODE_COMBINATION_ID                           |
-- | Description   : This Function will be used to fetch               |
-- |                 Code_combiantion_Id                               |
-- | Parameters    : Segment1,Segment2,Segment3,Segment4,Segment5      |
-- |                 Segmnet6,Segment7                                 |
-- |                                                                   |
-- | Returns       : Code_Combination_Id                               |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+----Modified Function for defect 3098 on  22-APR-10
          FUNCTION GET_CODE_COMBINATION_ID(p_segment1 VARCHAR2
                                          ,p_segment2 VARCHAR2
                                          ,p_segment3 VARCHAR2
                                          ,p_segment4 VARCHAR2
                                          ,p_segment5 VARCHAR2
                                          ,p_segment6 VARCHAR2
                                          ,p_segment7 VARCHAR2
                                          )
          RETURN NUMBER
          IS
               ln_coa_id                         NUMBER;
               ln_code_combination_id            NUMBER := 0;
               lc_segments                       VARCHAR2(150);
           BEGIN
             BEGIN
                 lc_segments := p_segment1||'.'||p_segment2||'.'||p_segment3||'.'||p_segment4||'.'||p_segment5||'.'||p_segment6||'.'||p_segment7;
                 SELECT chart_of_accounts_id
                 INTO   ln_coa_id
                 FROM   gl_sets_of_books
                 WHERE  set_of_books_id = fnd_profile.value('GL_SET_OF_BKS_ID');
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Chart Of Accounts Id Is - '||ln_coa_id);
              EXCEPTION
              WHEN OTHERS THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'No Chart Of Accounts Id' );
                RETURN 0;
                END;
                ln_code_combination_id := FND_FLEX_EXT.GET_CCID (
                                                          application_short_name  => 'SQLGL'
                                                         ,key_flex_code           => 'GL#'
                                                         ,structure_number        => ln_coa_id
                                                         ,validation_date         => SYSDATE
                                                         ,concatenated_segments   => lc_segments);
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Code Combination ID is - '||ln_code_combination_id );
             RETURN ln_code_combination_id;
             EXCEPTION
             WHEN OTHERS THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Unable to Derive Code Combination Id for the Segments'
                                                ||p_segment1||'.'
                                                ||p_segment2||'.'
                                                ||p_segment3||'.'
                                                ||p_segment4||'.'
                                                ||p_segment5||'.'
                                                ||p_segment6||'.'
                                                ||p_segment7
                                 );
                FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||'--'||SQLERRM);
                RETURN 0;
          END GET_CODE_COMBINATION_ID;
-- +===================================================================+
-- | Name          : DERIVE_COMPANY_FROM_LOCATION                      |
-- | Description   : This Function will be used to fetch Company       |
-- |                    ID for a Location    (FND_FLEX_VALUES     |
-- |                     _VL.flex_value) Segment4                      |
-- | Parameters    : Location (Segment4)                               |
-- |                                                                   |
-- |                                                                   |
-- | Returns       : Company                                           |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
    FUNCTION DERIVE_COMPANY_FROM_LOCATION (p_location IN VARCHAR2)
      RETURN VARCHAR2
     IS
         x_company fnd_flex_values_vl.attribute1%TYPE;
         BEGIN
             SELECT FFV.attribute1
             INTO x_company
             FROM fnd_flex_values FFV
                 ,fnd_flex_value_sets FFVS
             WHERE FFV.flex_value_set_id = FFVS.flex_value_set_id
             AND  FFVS.flex_value_set_name = 'OD_GL_GLOBAL_LOCATION'
             AND  FFV.flex_value = p_location;
             RETURN x_company;
              EXCEPTION
             WHEN NO_DATA_FOUND THEN
             RETURN NULL;
      END DERIVE_COMPANY_FROM_LOCATION;
END XX_GL_COGS_INT_MASTER_PKG;
/
SHO ERR;





