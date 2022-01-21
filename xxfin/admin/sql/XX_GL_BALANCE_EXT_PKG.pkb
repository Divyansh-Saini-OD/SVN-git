create or replace PACKAGE BODY XX_GL_BALANCE_EXT_PKG
AS
-- +====================================================================+
-- |                  Office Depot - Project Simplify                   |
-- |                       WIPRO Technologies                           |
-- +====================================================================+
-- | Name   :      GL Ledger balances extract program                   |
-- | Rice ID:      I1360                                                |
-- | Description : extracts Ledger balances from Oracle General Ledger  |
-- |               on a monthly as well as daily basis based on the     |
-- |               input parameters and writes it into a data file      |
-- |                                                                    |
-- |Change Record:                                                      |
-- |===============                                                     |
-- |Version   Date           Author              Remarks                |
-- |=======   ==========     ===============     =======================|
-- |  1.0     20-Jun-2008    Shabbar Hasan       Initial version        |
-- |  1.1     07-Jul-2008    Hemalatha S         Defect-8761-Changes in |
-- |                                             YTD files for the daily|
-- |                                             process.               |
-- |  1.2     14-Jul-2008    Hemalatha S         Defect-8930-Changes for|
-- |                                             changes in the zip     |
-- |                                             feature.               |
-- |  1.3     28-Jul-2008    Hemalatha S         Defect-9274-Added the  |
-- |                                             Parent Account and     |
-- |                                             Parent Cost Center.    |
-- |  1.4     07-Aug-2008    Hemalatha S         Defect-9274-Added the  |
-- |                                             rollup group conditions|
-- |  1.5     12-Sep-2008   Shabbar Hasan        Fixed Defect 11050     |
-- |                                                                    |
-- |  1.6     16-Sep-2008   Shabbar Hasan        Fixed Defect 11192     |
-- |  1.7     17-Oct-2008   Raji Natarajan       Fixed defect 12031     |
-- |  1.8     08-Jan-2010   Cindhu Nagarajan     CR 745/585 defect 2841 |
-- |                                             Release 1.2            |
-- |  1.9     17-Jun-2010   Cindhu Nagarajan     CR 634 Defect # 6428   |
-- |                                             Release 1.4            |
-- |  2.0     02-Sep-2010   Jude Felix           Added  hint for        |
-- |                                             performance defect 7186|
-- |                                             Added new column       |
-- |  2.1     07-Oct-2010   Mohammed Appas       Added the procedure    |
-- |                                             GL_BAL_MONTHLY_EXTRACT_|
-- |                                             CAD_MTD for            |
-- |                                             defect# 7916           |
-- |  2.2     24-Mar-2011   Abdul Khan	       Modified UTIL File       |
-- |                                             Close logic in         |
-- |                                             WRITE_TO_FILE for      |
-- |                                             Defect # 10225         |
-- |                                                                    |
-- |  2.3     13-Nov-2012   Paddy Sanjeevi       Defect 21004           |
-- |  2.4     01-Mar-2013   Paddy Sanjeevi       Defect 21004           |
-- |  2.5     17-JUN-2013   Kiran Kumar R        Included R12 Retrofit  |
-- |                                             Changes                |
-- |2.6       05-Nov-2015   Madhu Bolli    	 I1360 - R122 Retrofit Table Schema Removal(defect#36303)|
-- |2.7       17-Mar-2017   Paddy Sanjeevi  	 EU Fix                 |
-- |2.8       28-Mar-2017   Paddy Sanjeevi       GBP Tranvalue Fix      |
-- |3.0		  22-Oct-2021	Amit Kumar			 NAIT-199391 - Split Changes |
-- +====================================================================+

-- +====================================================================+
-- | Name : GET_PERIOD_NAME                                             |	
-- | Description : accepts period name as a parameter and returns       |
-- |               pre current period name and period num for p_count=2 |
-- |               and pre pre current period name and period num for   |
-- |               p_count=3                                            |
-- | Parameters :  x_period_name, x_period_num, p_count,                |
-- |               p_set_of_books_id, p_period_name                     |
-- | Returns :     Period Name                                          |
-- |               Period Num                                           |
-- +====================================================================+
PROCEDURE GET_PERIOD_NAME(x_period_name        OUT VARCHAR2
                         ,x_period_num         OUT VARCHAR2
                         ,p_count              IN  NUMBER
                         ,p_set_of_books_id    IN  NUMBER
                         ,p_period_name        IN  VARCHAR2
                        )
IS
  ld_start_date     DATE;
  ld_cnt_start_date DATE;
  ln_appl_id     fnd_application.application_id%TYPE;
BEGIN
  SELECT application_id
  INTO   ln_appl_id
  FROM   fnd_application
  WHERE  application_short_name = 'SQLGL';
  ---------Get Start Date of the current period------------
  SELECT GPS.start_date
  INTO   ld_start_date
  FROM   gl_period_statuses GPS
  --WHERE  GPS.set_of_books_id = p_set_of_books_id                                                --commented by kiran V(2.5) as per R12 Retrofit Change
  WHERE  GPS.ledger_id = p_set_of_books_id                                                        --added by kiran V(2.5) as per R12 Retrofit Change
  AND    GPS.application_id = ln_appl_id
  AND    GPS.period_name = p_period_name;
--  AND    GPS.period_name = UPPER(p_period_name);
  ---------IF p_count = 2, Get period name of the Pre Current period------------
  IF p_count = 2 THEN
    SELECT GP.period_name, LPAD(GP.period_num, 2,0)
    INTO   x_period_name, x_period_num
    FROM   gl_period_statuses GP
    WHERE  (ld_start_date - 1) BETWEEN GP.start_date AND GP.end_date
    --AND  GP.set_of_books_id = p_set_of_books_id                                                --commented by kiran V(2.5) as per R12 Retrofit Change
    AND  GP.ledger_id = p_set_of_books_id                                                        --added by kiran V(2.5) as per R12 Retrofit Changed
    AND    GP.application_id = ln_appl_id;
  ---------IF p_count = 3, Get period name of the Pre Pre Current period--------
  ELSIF p_count = 3 THEN
    SELECT GP.start_date - 1
    INTO   ld_cnt_start_date
    FROM   gl_period_statuses GP
    WHERE  (ld_start_date - 1) BETWEEN GP.start_date AND GP.end_date
    --AND  GP.set_of_books_id = p_set_of_books_id                                                --commented by kiran V(2.5) as per R12 Retrofit Change
    AND  GP.ledger_id = p_set_of_books_id                                                        --added by kiran V(2.5) as per R12 Retrofit Change
    AND    GP.application_id = ln_appl_id;
    SELECT GPP.period_name, LPAD(GPP.period_num, 2,0)
    INTO   x_period_name, x_period_num
    FROM   gl_period_statuses GPP
    WHERE  ld_cnt_start_date BETWEEN GPP.start_date AND GPP.end_date
    --AND  GPP.set_of_books_id = p_set_of_books_id                                                --commented by kiran V(2.5) as per R12 Retrofit Change
    AND  GPP.ledger_id = p_set_of_books_id                                                        --added by kiran V(2.5) as per R12 Retrofit Change
    AND    GPP.application_id = ln_appl_id;
  END IF;
EXCEPTION
WHEN NO_DATA_FOUND THEN
  IF p_count = 2 THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'No Pre Current Period found. ');
  ELSE
    FND_FILE.PUT_LINE(FND_FILE.LOG,'No Pre Pre Current Period found. ');
  END IF;
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while finding period name. ');
END GET_PERIOD_NAME;

-- +====================================================================+
-- | Name : GET_PERIOD_STATUS                                           |
-- | Description : accepts period name as a parameter and determines    |
-- |               whether the extract needs to be generated for the    |
-- |               given period. Returns a 1 if the extract needs to be |
-- |               generated and a 0 otherwise.                         |
-- | Parameters :  p_set_of_books_id, p_currency_code, p_period_name    |
-- +====================================================================+
FUNCTION GET_PERIOD_STATUS(p_set_of_books_id  NUMBER
                           ,p_currency_code   VARCHAR2
                           ,p_period_name     VARCHAR2)
RETURN NUMBER
IS
  ld_ext_date      DATE;
  ln_period_status NUMBER;
BEGIN
  ---------Get the date when extract for the given period name and SOB was last run-------
  BEGIN
    SELECT last_extract_date
    INTO   ld_ext_date
    FROM   xx_gl_daily_bal_extract
    WHERE  set_of_books_id = p_set_of_books_id
    AND    period_name = p_period_name;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 1;
  END;
  ---------Check if any new data has been added to GL_BALANCES after the extract was last run-------
  BEGIN
    SELECT 1
    INTO   ln_period_status
    FROM   gl_balances GB
           ,gl_code_combinations GCC
    --WHERE  GB.set_of_books_id = p_set_of_books_id                                              --commented by kiran V(2.5) as per R12 Retrofit Change
    WHERE  GB.ledger_id = p_set_of_books_id                                                      --added by kiran V(2.5) as per R12 Retrofit Change
    AND    GB.currency_code IN (p_currency_code, 'STAT')
    AND    GB.period_name = p_period_name
    AND    GB.actual_flag = 'A'
    AND    GCC.template_id IS NULL
    AND    GB.code_combination_id = GCC.code_combination_id
    AND    GB.last_update_date > ld_ext_date
    AND    ROWNUM = 1;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 0;
  END;
  RETURN ln_period_status;
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'GET_PERIOD_STATUS function ended due to an unexpected error. ' || SQLERRM);
  RETURN 0;
END GET_PERIOD_STATUS;


/*****************  Created New Write_to_File Procedure  /*****************/
                --- For R 1.2 CR 745 QC 2841 Fix
/***************************************************************************/
-- +====================================================================+
-- | Name : WRITE_TO_FILE                                               |
-- | Description : Extracts Ledger Balances for a given Period and      |
-- |               Set of Books and writes them into a .txt file and    |
-- |               archives the file                                    |
-- | Parameters :  p_file_name, p_source_file_path, p_set_of_books_id,  |
-- |               p_sob_name, p_coa_id, p_currency_code, p_period_name,|
-- |               p_appl_id                                            |
-- +====================================================================+

 PROCEDURE WRITE_TO_FILE(p_file_name              IN VARCHAR2
                        ,p_non_excluded_file      IN VARCHAR2
                        ,p_excluded_file_mtd      IN VARCHAR2  -- Added for the CR 634 Defect # 6428 - Release 1.4
                        ,p_non_excluded_file_mtd  IN VARCHAR2  -- Added for the CR 634 Defect # 6428 - Release 1.4
                        ,p_source_file_path       IN VARCHAR2
                        ,p_set_of_books_id        IN NUMBER
                        ,p_sob_name               IN VARCHAR2
                        ,p_coa_id                 IN NUMBER
                        ,p_currency_code          IN VARCHAR2
                        ,p_period_name            IN VARCHAR2
                        ,p_appl_id                IN NUMBER
                        ,p_acc_rolup_grp_name     IN VARCHAR2
                        ,p_cc_rolup_grp_name      IN VARCHAR2
                        )
IS
 --------- Local Variables Declaration---------
  lb_req_status                 BOOLEAN;
  lc_file_path                  VARCHAR2(500) := 'XXFIN_DAILY';
  lc_source_file_path           VARCHAR2(500) ;
  lc_dest_file_path             VARCHAR2(500) := '$XXFIN_DATA/ftp/out/hyperion';
  lc_archive_file_path          VARCHAR2(500) := '$XXFIN_ARCHIVE/outbound';
  lc_source_file_name           VARCHAR2(1000);
  lc_dest_file_name             VARCHAR2(1000);
  lc_phase                      VARCHAR2(50);
  lc_status                     VARCHAR2(50);
  lc_devphase                   VARCHAR2(50);
  lc_devstatus                  VARCHAR2(50);
  lc_message                    VARCHAR2(50);
  lc_error_msg                  VARCHAR2(4000);
  ln_req_id                     NUMBER(10);
  ln_msg_cnt                    NUMBER := 0;
  ln_cc_value_set_id            NUMBER; -- Defect 9274
  ln_acct_value_set_id          NUMBER;
  ln_buffer                     BINARY_INTEGER := 32767;
  ln_appl_id                    fnd_application.application_id%TYPE;
  ln_sob_ytd_bal_cad            NUMBER := 0;
  ln_sob_ytd_bal_usd            NUMBER := 0;
  ln_sob_ytd_bal_stat           NUMBER := 0;
  ln_com_count                  NUMBER :=0;
  ln_acc_rollup_grp             NUMBER;
  ln_cc_rollup_grp              NUMBER;
  ln_error_flag                 NUMBER := 0;
  lt_file_excluded              UTL_FILE.FILE_TYPE;
  lt_file_non_exld              UTL_FILE.FILE_TYPE;
  lc_loc_non_exld               VARCHAR2(2000);
  lc_source_file_excluded       VARCHAR2(2000);
  lc_dest_file_excluded         VARCHAR2(2000);
  ln_req_id_exld                NUMBER(10);
  lb_req_status_exld            BOOLEAN;
  lc_file_flag_exld             VARCHAR2(3) := 'N';
  lc_file_flag_non_exld         VARCHAR2(3) := 'N';
  lc_previous_company           gl_code_combinations.segment1%TYPE := NULL;
  lc_scenario_non_exld          VARCHAR2(200);
  lc_layer_non_exld             VARCHAR2(200);
  lc_scenario_print             VARCHAR2(200);        --Added by Mohammed Appas A on 24-Nov-2010
  lc_layer_print                VARCHAR2(200);        --Added by Mohammed Appas A on 24-Nov-2010

/*****************R 1.4 CR 634 QC DefectID#6428 Fix****************Start****************/

  lt_file_excluded_mtd          UTL_FILE.FILE_TYPE;
  lt_file_non_exld_mtd          UTL_FILE.FILE_TYPE;
  ln_sob_mtd_bal_cad            NUMBER := 0;
  ln_sob_mtd_bal_usd            NUMBER := 0;
  ln_sob_mtd_bal_stat           NUMBER := 0;
  lc_source_file_excluded_mtd   VARCHAR2(2000);
  lc_dest_file_name_mtd         VARCHAR2(2000);
  lc_source_file_name_mtd       VARCHAR2(2000);
  lc_dest_file_excluded_mtd     VARCHAR2(2000);
  ln_req_id_exld_mtd            NUMBER(10);
  lb_req_status_exld_mtd        BOOLEAN;
  ln_req_id_mtd                 NUMBER(10);
  lb_req_status_mtd             BOOLEAN;

/*****************R 1.4 CR 634 QC DefectID#6428 Fix****************Ends****************/


  ------- Cursor to get Excluded company ledger balances details --------
  CURSOR lcu_ledger_excl
  IS
     SELECT  period_name
            ,actual_flag
            ,period_year
            ,currency_code
            ,company
            ,acct_parent
            ,segment3
            ,acct_description
            ,cc_parent
            ,segment2
            ,segment4
            ,segment6
            ,SUM(ytd_bal) net_bal
            ,SUM(mtd_bal) net_bal_mtd  -- Added for the CR 634 Defect # 6428 - Release 1.4
     FROM   xx_gl_bal_ext_temp XGBET
     WHERE EXISTS (SELECT 1
                   FROM  xx_fin_translatedefinition  XFTD
                       , xx_fin_translatevalues      XFTV
                   WHERE XFTV.translate_id = XFTD.translate_id
                     AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
                     AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
                     AND XFTV.source_value1 = 'Excluded_company'
                     AND XFTV.target_value1 = XGBET.company
                     AND XFTD.translation_name = 'XX_GL_1360_BALANCE_EXT'
                     AND XFTV.enabled_flag = 'Y'
                     AND XFTD.enabled_flag = 'Y'
                  )
    GROUP BY period_name
            ,Actual_Flag
            ,period_year
            ,currency_code
            ,company
            ,acct_parent
            ,segment3
            ,acct_description
            ,cc_parent
            ,segment2
            ,segment4
            ,segment6
    ORDER BY company;

  ------- Cursor to get Non Excluded company ledger balances details --------
  CURSOR lcu_ledger_non_excl
  IS
     SELECT scenario
           ,period
           ,year
           ,company
           ,segment3
           ,segment2
           ,segment6
           ,segment4
           ,currency_code
           ,layer
           ,SUM(ytd_bal) net_bal
           ,SUM(mtd_bal) net_bal_mtd  -- Added for the CR 634 Defect # 6428 - Release 1.4
     FROM  xx_gl_bal_ext_temp XGBET
     WHERE NOT EXISTS (SELECT 1
                       FROM xx_fin_translatedefinition  XFTD
                           ,xx_fin_translatevalues      XFTV
                       WHERE XFTV.translate_id = XFTD.translate_id
                       AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
                       AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
                       AND XFTV.source_value1 = 'Excluded_company'
                       AND XFTV.target_value1 = XGBET.company
                       AND XFTD.translation_name = 'XX_GL_1360_BALANCE_EXT'
                       AND XFTV.enabled_flag = 'Y'
                       AND XFTD.enabled_flag = 'Y'
                      )
     GROUP BY scenario
             ,period
             ,year
             ,company
             ,segment3
             ,segment2
             ,segment6
             ,segment4
             ,currency_code
             ,layer
     ORDER BY company;

  CURSOR lcu_loc_translate
  IS
     SELECT XFTV.target_value2
           ,XFTV.source_value2
     FROM   xx_fin_translatedefinition  XFTD
           ,xx_fin_translatevalues      XFTV
     WHERE  XFTV.translate_id = XFTD.translate_id
     AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
     AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
     AND XFTD.translation_name = 'XX_GL_1360_BALANCE_EXT'
     AND XFTV.enabled_flag = 'Y'
     AND XFTD.enabled_flag = 'Y'
     AND source_value2 IS NOT NULL;

  CURSOR lcu_amt_reciprocal
  IS
     SELECT XFTV.source_value3
     FROM   xx_fin_translatedefinition  XFTD
           ,xx_fin_translatevalues      XFTV
     WHERE XFTV.translate_id = XFTD.translate_id
     AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
     AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
     AND XFTD.translation_name = 'XX_GL_1360_BALANCE_EXT'
     AND XFTV.enabled_flag = 'Y'
     AND XFTD.enabled_flag = 'Y'
     AND source_value3 IS NOT NULL;

  CURSOR lcu_layer_translate
  IS
     SELECT XFTV.target_value4
           ,XFTV.source_value4
     FROM  xx_fin_translatedefinition  XFTD
          ,xx_fin_translatevalues      XFTV
     WHERE XFTV.translate_id = XFTD.translate_id
     AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
     AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
 --  AND XFTV.source_value2 = (SUBSTR(ltab_ref(i).segment4,1,1))
     AND XFTD.translation_name = 'XX_GL_1360_BALANCE_EXT'
     AND XFTV.enabled_flag = 'Y'
     AND XFTD.enabled_flag = 'Y'
     AND source_value4 IS NOT NULL;

  PROCEDURE insert_temp_table
  IS
  --------Cursor Query for extracting GL Balances---------
  CURSOR lcu_ledger_balances(p_acct_value_set_id IN NUMBER
                            ,p_cc_value_set_id   IN NUMBER
                            ,p_acc_rollup_grp    IN NUMBER
                            ,p_cc_rollup_grp     IN NUMBER
                            ,p_coa_id            IN NUMBER
                            )
  IS
---------Query to fetch the records where the parents exist for both account and cost center---------
 -- Added hint for performance defect 7186
  SELECT   /*+ leading(GLB) no_merge(AC) no_merge(AC1) no_merge(CC1) */
          GLB.period_name
         ,INITCAP(TO_CHAR(TO_DATE(GLB.period_name,'MON-RR'),'MON')) period
         ,GLB.actual_flag
         ,GLB.period_year
         ,TO_CHAR(TO_DATE(GLB.period_year,'RRRR'),'RR') year
         ,GCC.segment1    company
         ,GCC.segment2
         ,GCC.segment3
         ,AC_PAR.parent_flex_value acct_parent
         ,CC_PAR.parent_flex_value cc_parent
         ,AC.description acct_description
         ,GCC.segment4
         ,GCC.segment5
         ,GCC.segment6
         ,GCC.segment7
         ,GLB.currency_code
         ,(begin_balance_dr-begin_balance_cr + period_net_dr-period_net_cr) ytd_bal
         ,'' scenario
         ,'' layer
         ,period_net_dr-period_net_cr  mtd_bal     -- Added For CR # 634 Defect # 6428 - R 1.4
   FROM   gl_balances                   GLB
         ,gl_code_combinations          GCC
         ,fnd_flex_values_vl            AC
         ,fnd_flex_values_vl            AC1
         ,fnd_flex_value_norm_hierarchy AC_PAR
         ,fnd_flex_values_vl            CC1
         ,fnd_flex_value_norm_hierarchy CC_PAR
  --WHERE  GLB.set_of_books_id       = p_set_of_books_id                                 --commented by kiran V(2.5) as per R12 Retrofit Change
  WHERE  GLB.ledger_id       = p_set_of_books_id                                         --added by kiran V(2.5) as per R12 Retrofit Change
  AND    GLB.code_combination_id   = GCC.code_combination_id
  AND    GLB.currency_code IN (p_currency_code, 'STAT')
  AND    GLB.period_name = p_period_name
  AND    GLB.actual_flag = 'A'
  AND    GCC.template_id IS NULL
  AND    GCC.chart_of_accounts_id = p_coa_id
  AND    CC_PAR.parent_flex_value = CC1.flex_value
  AND    CC1.flex_value_set_id = p_cc_value_set_id
  AND    CC1.structured_hierarchy_level = p_cc_rollup_grp
  AND    CC_PAR.flex_value_set_id = p_cc_value_set_id
  AND    GCC.segment2 BETWEEN CC_PAR.child_flex_value_low AND CC_PAR.child_flex_value_high
  AND    AC_PAR.parent_flex_value = AC1.flex_value
  AND    AC1.flex_value_set_id = p_acct_value_set_id
  AND    AC1.structured_hierarchy_level = p_acc_rollup_grp
  AND    AC.flex_value_set_id = p_acct_value_set_id
  AND    AC_PAR.flex_value_set_id = p_acct_value_set_id
  AND    AC.flex_value BETWEEN AC_PAR.child_flex_value_low AND AC_PAR.child_flex_value_high
  AND    AC.flex_value = gcc.segment3
  AND    AC1.enabled_flag = 'Y'
  AND    AC.enabled_flag = 'Y'
  AND    CC1.enabled_flag = 'Y'
  UNION ALL
---------Query to fetch values where account parent does not exist and cost center parent exist---------
 -- Added hint for performance defect 7186
  SELECT /*+ leading(GLB) no_merge(AC) no_merge(CC1)*/
          GLB.period_name
         ,INITCAP(TO_CHAR(TO_DATE(GLB.period_name,'MON-RR'),'MON')) period
         ,GLB.actual_flag
         ,GLB.period_year
         ,TO_CHAR(TO_DATE(GLB.period_year,'RRRR'),'RR') year
         ,GCC.segment1    company
         ,GCC.segment2
         ,GCC.segment3
         ,'' acct_parent
         ,CC_PAR.parent_flex_value cc_parent
         ,AC.description acct_description
         ,GCC.segment4
         ,GCC.segment5
         ,GCC.segment6
         ,GCC.segment7
         ,GLB.currency_code
         ,(begin_balance_dr-begin_balance_cr + period_net_dr-period_net_cr) ytd_bal
         ,'' scenario
         ,'' layer
         ,period_net_dr-period_net_cr  mtd_bal     -- Added For CR # 634 Defect # 6428 - R 1.4
  FROM    gl_balances                   GLB
         ,gl_code_combinations          GCC
         ,fnd_flex_values_vl            AC
         ,fnd_flex_values_vl            CC1
         ,fnd_flex_value_norm_hierarchy CC_PAR
   --WHERE  GLB.set_of_books_id       = p_set_of_books_id                                 --commented by kiran V(2.5) as per R12 Retrofit Change
  WHERE  GLB.ledger_id       = p_set_of_books_id                                         --added by kiran V(2.5) as per R12 Retrofit Change
  AND    GLB.code_combination_id   = GCC.code_combination_id
  AND    AC.flex_value_set_id = p_acct_value_set_id
  AND    AC.flex_value = GCC.segment3
  AND    AC.enabled_flag = 'Y'
  AND NOT EXISTS( SELECT /*+ use_hash(AC1 AC_PAR)*/  1
                  FROM fnd_flex_value_norm_hierarchy AC_PAR , fnd_flex_values AC1
                  WHERE AC_PAR.flex_value_set_id = p_acct_value_set_id
                  AND GCC.segment3 BETWEEN AC_PAR.child_flex_value_low AND AC_PAR.child_flex_value_high
                  AND AC1.flex_value = AC_PAR.parent_flex_value
                  AND AC1.flex_value_set_id = p_acct_value_set_id
                  AND AC1.structured_hierarchy_level = p_acc_rollup_grp
                  AND AC1.enabled_flag = 'Y'
                )
  AND    CC_PAR.parent_flex_value = CC1.flex_value
  AND    CC1.flex_value_set_id = p_cc_value_set_id
  AND    CC1.structured_hierarchy_level = p_cc_rollup_grp
  AND    CC_PAR.flex_value_set_id = p_cc_value_set_id
  AND    GCC.segment2 BETWEEN CC_PAR.child_flex_value_low AND CC_PAR.child_flex_value_high
  AND    GLB.currency_code IN (p_currency_code, 'STAT')
  AND    GLB.period_name = p_period_name
  AND    GLB.actual_flag = 'A'
  AND    GCC.template_id IS NULL
  AND    CC1.enabled_flag = 'Y'
  AND    GCC.chart_of_accounts_id = p_coa_id
  UNION ALL
---------Query to fetch records where both cost center parent and account parent do not exist---------
 -- Added hint for performance defect 7186
  SELECT  /*+ leading(GLB) no_merge(AC) */
          GLB.period_name
         ,INITCAP(TO_CHAR(TO_DATE(GLB.period_name,'MON-RR'),'MON')) period
         ,GLB.actual_flag
         ,GLB.period_year
         ,TO_CHAR(TO_DATE(GLB.period_year,'RRRR'),'RR') year
         ,GCC.segment1    company
         ,GCC.segment2
         ,GCC.segment3
         ,'' acct_parent
         ,'' cc_parent
         ,AC.description acct_description
         ,GCC.segment4
         ,GCC.segment5
         ,GCC.segment6
         ,GCC.segment7
         ,GLB.currency_code
         ,(begin_balance_dr-begin_balance_cr + period_net_dr-period_net_cr) ytd_bal
         ,'' scenario
         ,'' layer
         ,period_net_dr-period_net_cr  mtd_bal     -- Added For CR # 634 Defect # 6428 - R 1.4
  FROM   gl_balances GLB
        ,gl_code_combinations GCC
        ,fnd_flex_values_vl AC
   --WHERE  GLB.set_of_books_id       = p_set_of_books_id                                 --commented by kiran V(2.5) as per R12 Retrofit Change
  WHERE  GLB.ledger_id       = p_set_of_books_id                                         --added by kiran V(2.5) as per R12 Retrofit Change
  AND    GLB.code_combination_id   = GCC.code_combination_id
  AND    AC.flex_value_set_id = p_acct_value_set_id
  AND    AC.flex_value = gcc.segment3
  AND    AC.enabled_flag = 'Y'
  AND NOT EXISTS( SELECT /*+ use_hash(AC1 AC_PAR)*/  1
                  FROM fnd_flex_value_norm_hierarchy AC_PAR , fnd_flex_values AC1
                  WHERE AC_PAR.flex_value_set_id = p_acct_value_set_id
                  AND GCC.segment3 BETWEEN AC_PAR.child_flex_value_low AND AC_PAR.child_flex_value_high
                  AND AC1.flex_value = AC_PAR.parent_flex_value
                  AND AC1. flex_value_set_id = p_acct_value_set_id
                  AND AC1.structured_hierarchy_level = p_acc_rollup_grp
                  AND AC1.enabled_flag = 'Y'
                )
  AND NOT EXISTS( SELECT /*+ use_hash(CC1 CC_PAR)*/  1
                  FROM fnd_flex_value_norm_hierarchy CC_PAR, fnd_flex_values CC1
                  WHERE CC_PAR.flex_value_set_id = p_cc_value_set_id
                  AND GCC.segment2 BETWEEN CC_PAR.child_flex_value_low AND CC_PAR.child_flex_value_high
                  AND CC1.flex_value = CC_PAR.parent_flex_value
                  AND CC1. flex_value_set_id = p_cc_value_set_id
                  AND CC1.structured_hierarchy_level = p_cc_rollup_grp
                  AND CC1.enabled_flag = 'Y'
                )
  AND    GLB.currency_code IN (p_currency_code, 'STAT')
  AND    GLB.period_name = p_period_name
  AND    GLB.actual_flag = 'A'
  AND    GCC.template_id IS NULL
  AND    GCC.chart_of_accounts_id = p_coa_id
  UNION ALL
---------Query to fetch the records where parent account exists but parent cost center does not exist---------
-- Added hint for performance defect 7186
SELECT /*+ leading(GLB) no_merge(AC) no_merge(AC1)*/
          GLB.period_name
         ,INITCAP(TO_CHAR(TO_DATE(GLB.period_name,'MON-RR'),'MON')) period
         ,GLB.actual_flag
         ,GLB.period_year
         ,TO_CHAR(TO_DATE(GLB.period_year,'RRRR'),'RR') year
         ,GCC.segment1    company
         ,GCC.segment2
         ,GCC.segment3
         ,AC_PAR.parent_flex_value acct_parent
         ,'' cc_parent
         ,AC.description acct_description
         ,GCC.segment4
         ,GCC.segment5
         ,GCC.segment6
         ,GCC.segment7
         ,GLB.currency_code
         ,(begin_balance_dr-begin_balance_cr + period_net_dr-period_net_cr) ytd_bal
         ,'' scenario
         ,'' layer
         ,period_net_dr-period_net_cr  mtd_bal     -- Added For CR # 634 Defect # 6428 - R 1.4
  FROM   gl_balances GLB
         ,gl_code_combinations GCC
         ,fnd_flex_values_vl AC
         ,fnd_flex_values_vl AC1
         ,fnd_flex_value_norm_hierarchy AC_PAR
  --WHERE  GLB.set_of_books_id       = p_set_of_books_id                                 --commented by kiran V(2.5) as per R12 Retrofit Change
  WHERE  GLB.ledger_id       = p_set_of_books_id                                         --added by kiran V(2.5) as per R12 Retrofit Change
  AND    GLB.code_combination_id   = GCC.code_combination_id
  AND    AC_PAR.parent_flex_value = AC1.flex_value
  AND    AC1.flex_value_set_id = p_acct_value_set_id
  AND    AC1.structured_hierarchy_level = p_acc_rollup_grp
  AND    AC.flex_value_set_id = p_acct_value_set_id
  AND    AC_PAR.flex_value_set_id = p_acct_value_set_id
  AND    AC.flex_value BETWEEN AC_PAR.child_flex_value_low AND AC_PAR.child_flex_value_high
  AND    AC.flex_value = gcc.segment3
  AND    AC.enabled_flag = 'Y'
  AND    AC1.enabled_flag = 'Y'
  AND NOT EXISTS( SELECT /*+ use_hash(CC1 CC_PAR)*/  1
                  FROM fnd_flex_value_norm_hierarchy CC_PAR, fnd_flex_values CC1
                  WHERE CC_PAR.flex_value_set_id = p_cc_value_set_id
                  AND   GCC.segment2 BETWEEN CC_PAR.child_flex_value_low AND CC_PAR.child_flex_value_high
                  AND   CC1.flex_value = CC_PAR.parent_flex_value
                  AND   CC1. flex_value_set_id = p_cc_value_set_id
                  AND   CC1.structured_hierarchy_level = p_cc_rollup_grp
                  AND   CC1.enabled_flag = 'Y'
                )
  AND    GLB.currency_code IN (p_currency_code, 'STAT')
  AND    GLB.period_name = p_period_name
  AND    GLB.actual_flag = 'A'
  AND    GCC.template_id IS NULL
  AND    GCC.chart_of_accounts_id = p_coa_id;

  CURSOR lcu_get_exclu_company (p_ledg_Comp VARCHAR2)
  IS
     SELECT XFTV.target_value1 exclud_company
     FROM   xx_fin_translatedefinition  XFTD
           ,xx_fin_translatevalues      XFTV
     WHERE XFTV.translate_id = XFTD.translate_id
     AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
     AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
     AND XFTV.source_value1 = 'Excluded_company'
     AND XFTV.target_value1 = p_ledg_comp
     AND XFTD.translation_name = 'XX_GL_1360_BALANCE_EXT'
     AND XFTV.enabled_flag = 'Y'
     AND XFTD.enabled_flag = 'Y';

     TYPE ltab_ref_type IS TABLE OF lcu_ledger_balances%ROWTYPE;
     ltab_ref                      ltab_ref_type;

     lt_exclcomp_details           lcu_get_exclu_company%ROWTYPE;
     lc_company_exld_Flag          VARCHAR2(1) := 'N';
     lc_layer_translated           VARCHAR2(1000);
     lc_parent_acc                 CONSTANT fnd_flex_value_norm_hierarchy.parent_flex_value%TYPE := 'P8000000'; -- Defect 9274
     lc_loc_translated             VARCHAR2(2000);
     ln_ytd_bal                    NUMBER;
     lc_scenario_translated        VARCHAR2(2000);
     lc_gl_acct                    VARCHAR2(2000);
     lc_acct_layer                 VARCHAR2(1000);

--------- pl/sql table to hold customer details---------

     TYPE rec_sob_details IS RECORD (period_name       xx_gl_bal_ext_temp.period_name%TYPE
                                    ,period            xx_gl_bal_ext_temp.period%TYPE
                                    ,actual_flag       xx_gl_bal_ext_temp.actual_flag%TYPE
                                    ,period_year       xx_gl_bal_ext_temp.period_year%TYPE
                                    ,year              xx_gl_bal_ext_temp.year%TYPE
                                    ,company           xx_gl_bal_ext_temp.company%TYPE
                                    ,segment2          xx_gl_bal_ext_temp.segment2%TYPE
                                    ,segment3          xx_gl_bal_ext_temp.segment3%TYPE
                                    ,acct_parent       xx_gl_bal_ext_temp.acct_parent%TYPE
                                    ,cc_parent         xx_gl_bal_ext_temp.cc_parent%TYPE
                                    ,acct_description  xx_gl_bal_ext_temp.acct_description%TYPE
                                    ,segment4          xx_gl_bal_ext_temp.segment4%TYPE
                                    ,segment5          xx_gl_bal_ext_temp.segment5%TYPE
                                    ,segment6          xx_gl_bal_ext_temp.segment6%TYPE
                                    ,segment7          xx_gl_bal_ext_temp.segment7%TYPE
                                    ,currency_code     xx_gl_bal_ext_temp.currency_code%TYPE
                                    ,ytd_bal           xx_gl_bal_ext_temp.ytd_bal%TYPE
                                    ,scenario          xx_gl_bal_ext_temp.scenario%TYPE
                                    ,layer             xx_gl_bal_ext_temp.layer%TYPE
                                    ,mtd_bal           xx_gl_bal_ext_temp.mtd_bal%TYPE   -- Added For CR # 634 Defect # 6428 - R 1.4
                                    );

     lr_sob_details          rec_sob_details;

     TYPE tab_sob_details IS TABLE OF lr_sob_details%TYPE
     INDEX BY BINARY_INTEGER;

     lt_sob_details           tab_sob_details;

 BEGIN
     EXECUTE IMMEDIATE ('TRUNCATE TABLE xxfin.xx_gl_bal_ext_temp');

   OPEN lcu_ledger_balances(ln_acct_value_set_id,ln_cc_value_set_id,ln_acc_rollup_grp,ln_cc_rollup_grp,p_coa_id);
   LOOP
    FETCH lcu_ledger_balances BULK COLLECT INTO lt_sob_details LIMIT 10000;
    IF lt_sob_details.COUNT > 0 THEN
     FORALL i IN 1..lt_sob_details.LAST
      INSERT INTO xx_gl_bal_ext_temp
      VALUES lt_sob_details(i);
    --COMMIT;
    ELSE
      EXIT;
    END IF;
   END LOOP;
   CLOSE lcu_ledger_balances;
   COMMIT;

  --------- Update the temp table for Excluded Company  ---------
    UPDATE xx_gl_bal_ext_temp XGBET
    SET acct_parent =  lc_parent_acc
    WHERE SUBSTR(segment3,1,1) = '8'
    AND EXISTS ( SELECT 1
                 FROM  xx_fin_translatedefinition  XFTD
                     , xx_fin_translatevalues      XFTV
                 WHERE XFTV.translate_id = XFTD.translate_id
                 AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
                 AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
                 AND XFTV.source_value1 = 'Excluded_company'
                 AND XFTV.target_value1 = XGBET.company
                 AND XFTD.translation_name = 'XX_GL_1360_BALANCE_EXT'
                 AND XFTV.enabled_flag = 'Y'
                 AND XFTD.enabled_flag = 'Y'
               );
---------  Update the temp table for Non-Excluded Company  ---------
    FOR lr_loc_translate IN lcu_loc_translate
    LOOP
       UPDATE xx_gl_bal_ext_temp XGBET
       SET segment4 =  lr_loc_translate.target_value2
       WHERE SUBSTR(XGBET.segment4,1,1) = lr_loc_translate.source_value2
       AND NOT EXISTS (SELECT 1
                       FROM  xx_fin_translatedefinition  XFTD
                           , xx_fin_translatevalues      XFTV
                       WHERE XFTV.translate_id = XFTD.translate_id
                       AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
                       AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
                       AND XFTV.source_value1 = 'Excluded_company'
                       AND XFTV.target_value1 = XGBET.company
                       AND XFTD.translation_name = 'XX_GL_1360_BALANCE_EXT'
                       AND XFTV.enabled_flag = 'Y'
                       AND XFTD.enabled_flag = 'Y'
                      );
    END LOOP;

    FOR lr_amt_reciprocal IN lcu_amt_reciprocal
    LOOP
       UPDATE xx_gl_bal_ext_temp XGBET
       SET ytd_bal =  ytd_bal * (-1)
          ,mtd_bal =  mtd_bal * (-1)
       WHERE SUBSTR(XGBET.segment3,1,1) = lr_amt_reciprocal.source_value3
       AND NOT EXISTS (SELECT 1
                       FROM  xx_fin_translatedefinition  XFTD
                           , xx_fin_translatevalues      XFTV
                       WHERE XFTV.translate_id = XFTD.translate_id
                       AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
                       AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
                       AND XFTV.source_value1 = 'Excluded_company'
                       AND XFTV.target_value1 = XGBET.company
                       AND XFTD.translation_name = 'XX_GL_1360_BALANCE_EXT'
                       AND XFTV.enabled_flag = 'Y'
                       AND XFTD.enabled_flag = 'Y'
                      );
    END LOOP;

    FOR lr_layer_translate IN lcu_layer_translate
    LOOP
       UPDATE xx_gl_bal_ext_temp XGBET
       SET layer =  lr_layer_translate.target_value4
       WHERE segment3 = lr_layer_translate.source_value4
       AND NOT EXISTS (SELECT 1
                       FROM  xx_fin_translatedefinition  XFTD
                           , xx_fin_translatevalues      XFTV
                       WHERE XFTV.translate_id = XFTD.translate_id
                       AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
                       AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
                       AND XFTV.source_value1 = 'Excluded_company'
                       AND XFTV.target_value1 = XGBET.company
                       AND XFTD.translation_name = 'XX_GL_1360_BALANCE_EXT'
                       AND XFTV.enabled_flag = 'Y'
                       AND XFTD.enabled_flag = 'Y'
                      );
    END LOOP;
 EXCEPTION
    WHEN OTHERS THEN
       FND_FILE.PUT_LINE(FND_FILE.log,'Exception raised while Inserting Records into Temp table. '|| SQLERRM);
 END;   --- End of Insert temp table procedure

    ---------  Main Procedure Starts Here to write in files  ---------
 BEGIN
          lc_source_file_path := p_source_file_path;
          ln_appl_id := p_appl_id;
          FND_FILE.PUT_LINE(FND_FILE.LOG,'*************************************************************');
          FND_FILE.PUT_LINE(FND_FILE.LOG,'SOB Name     : ' || p_sob_name);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Currency     : ' || p_currency_code);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Period Name  : ' || p_period_name);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'-------------------------------------------------------------');
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'*************************************************************');
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'SOB Name      : ' || p_sob_name);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Currency      : ' || p_currency_code);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Period Name   : ' || p_period_name);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------------------------');
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The GL Balance Extract File Name for  Excluded Company                     :   ' || p_file_name);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The GL Balance Extract File Name for non Excluded Company                  :   ' ||p_non_excluded_file);  -- Added for CR 745 Defect 2841 R 1.2
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The GL Balance Extract File Name for  Excluded Company for MTD Balances    :   ' || p_excluded_file_mtd); -- Added For CR # 634 Defect # 6428 - R 1.4
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The GL Balance Extract File Name for non Excluded Company for MTD Balances :   ' ||p_non_excluded_file_mtd); -- Added For CR # 634 Defect # 6428 - R 1.4
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------------------------');                          -- Added for CR 745 Defect 2841 R 1.2
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Created File Path               : ' || lc_file_path);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Destination File Path           : ' || lc_dest_file_path);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'*************************************************************');
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'Start Time ' || TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
          FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

--------Query for fetching flex_value_set_ids for Accounts and Cost Centers---------
  BEGIN
    SELECT distinct FFV_CC.flex_value_set_id
           ,FFV_AC.flex_value_set_id
    INTO   ln_cc_value_set_id
           ,ln_acct_value_set_id
    FROM   fnd_flex_value_sets FFV_CC
           ,fnd_id_flex_segments FSG_CC
           ,fnd_flex_value_sets FFV_AC
           ,fnd_id_flex_segments FSG_AC
    WHERE  FSG_CC.segment_name = 'Cost Center'
    AND    FSG_CC.flex_value_set_id = FFV_CC.flex_value_set_id
    AND    FSG_CC.id_flex_num = p_coa_id
    AND    FSG_AC.segment_name = 'Account'
    AND    FSG_AC.id_flex_num = p_coa_id
    AND    FSG_AC.flex_value_set_id = FFV_AC.flex_value_set_id;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Value Set IDs not found for Account and Cost Center. '
                                    || SQLERRM);
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching Value Set IDs for Account and Cost Center. '
                                    || SQLERRM);
  END;

   --------Query for fetching hierarchy_id for Report Line    ---------
  BEGIN
    SELECT ACC.hierarchy_id
    INTO   ln_acc_rollup_grp
    FROM   fnd_flex_hierarchies_vl ACC
    WHERE  ACC.hierarchy_code = p_acc_rolup_grp_name
    AND    ACC.flex_value_set_id = ln_acct_value_set_id;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Hierarchy IDs not found for Report Line. '
                                    || SQLERRM);
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching Hierarchy IDs not found for Report Line. '
                                    || SQLERRM);
  END;
  --------Query for fetching hierarchy_id for External       ---------
  BEGIN
    SELECT CC.hierarchy_id
    INTO   ln_cc_rollup_grp
    FROM   fnd_flex_hierarchies_vl CC
    WHERE  CC.hierarchy_code = p_cc_rolup_grp_name
    AND    CC.flex_value_set_id = ln_cc_value_set_id;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Hierarchy IDs not found for External. ');
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching Hierarchy IDs not found for External. '
                                    || SQLERRM);
  END;

  -----------Calling Insert Temp Table for Inserting records into Temp Table   --------------
     insert_temp_table;

     lc_previous_company  := NULL;

  --------  Writing Into File For Excluded Company   --------

   FOR lr_ledger_balances IN lcu_ledger_excl
   LOOP
      IF(lc_previous_company <> lr_ledger_balances.COMPANY) THEN
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Company: ' || lc_previous_company ||'  Number of rows extracted: '||ln_com_count);
        ln_com_count := 0;
      END IF;
        ln_com_count := ln_com_count+1;
        lc_previous_company := lr_ledger_balances.COMPANY;
      IF NOT UTL_FILE.is_open(lt_file_excluded) THEN
       BEGIN
         lt_file_excluded := UTL_FILE.fopen(lc_file_path, p_file_name,'w',ln_buffer);
         lc_file_flag_exld:='Y';
       EXCEPTION
         WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised while Opening the Excluded file. '|| SQLERRM);
       END;
      END IF;

/*****************R 1.4 CR 634 QC DefectID#6428 Fix****************Start****************/

      IF NOT UTL_FILE.is_open(lt_file_excluded_mtd) THEN
       BEGIN
         lt_file_excluded_mtd := UTL_FILE.fopen(lc_file_path, p_excluded_file_mtd,'w',ln_buffer);
         lc_file_flag_exld:='Y';
       EXCEPTION
         WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised while Opening the Excluded file for MTD balances. '|| SQLERRM);
       END;
      END IF;

/*****************R 1.4 CR 634 QC DefectID#6428 Fix****************Ends****************/


  -------- Calculation of postal amounts for Excluded company  --------
      IF(lr_ledger_balances.currency_code = 'CAD') THEN
         ln_sob_ytd_bal_cad := ln_sob_ytd_bal_cad + lr_ledger_balances.Net_Bal;
      ELSIF(lr_ledger_balances.currency_code = 'USD')THEN
         ln_sob_ytd_bal_usd := ln_sob_ytd_bal_usd + lr_ledger_balances.Net_Bal;
      ELSE
         ln_sob_ytd_bal_stat := ln_sob_ytd_bal_stat + lr_ledger_balances.Net_Bal;
      END IF;

/*****************R 1.4 CR 634 QC DefectID#6428 Fix****************Start****************/

  -------- Calculation of postal amounts for Excluded company for MTD balances --------

      IF(lr_ledger_balances.currency_code = 'CAD') THEN
         ln_sob_mtd_bal_cad := ln_sob_mtd_bal_cad + lr_ledger_balances.Net_Bal_mtd;
      ELSIF(lr_ledger_balances.currency_code = 'USD')THEN
         ln_sob_mtd_bal_usd := ln_sob_mtd_bal_usd + lr_ledger_balances.Net_Bal_mtd;
      ELSE
         ln_sob_mtd_bal_stat := ln_sob_mtd_bal_stat + lr_ledger_balances.Net_Bal_mtd;
      END IF;

/*****************R 1.4 CR 634 QC DefectID#6428 Fix****************Ends****************/


  --------   Writing GL Balances into text file for Excluded Company    --------
           BEGIN
              UTL_FILE.PUT_LINE(lt_file_excluded, p_sob_name                     -- SOB Short name
                               || '|'   ||lr_ledger_balances.actual_flag         -- Actual Flag
                               || '|'   ||lr_ledger_balances.period_name         -- Period
                               || '|'   ||lr_ledger_balances.period_year         -- Year
                               || '|'   ||lr_ledger_balances.currency_code       -- Currency
                               || '|'   ||lr_ledger_balances.company             -- Company
                               || '|'   ||lr_ledger_balances.acct_parent         -- Parent Account
                               || '|'   ||lr_ledger_balances.segment3            -- Account
                               || '|'   ||lr_ledger_balances.acct_description    -- Account Description
                               || '|'   ||lr_ledger_balances.cc_parent           -- Parent Cost Center -- Defect 9274
                               || '|'   ||lr_ledger_balances.segment2            -- Cost Center
                               || '|'   ||lr_ledger_balances.segment4            -- Location
                               || '|'   ||lr_ledger_balances.segment6            -- LOB
                               || '|'   ||lr_ledger_balances.net_bal             -- NET YTD Balance
                               );
           EXCEPTION
              WHEN OTHERS THEN
                  ln_error_flag := 1;
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while writing into Text file for excluded company '|| SQLERRM);
           END;
/*****************R 1.4 CR 634 QC DefectID#6428 Fix****************Start****************/

  --------   Writing GL Balances into text file for Excluded Company for MTD Balances  --------

           BEGIN
              UTL_FILE.PUT_LINE(lt_file_excluded_mtd, p_sob_name                 -- SOB Short name
                               || '|'   ||lr_ledger_balances.actual_flag         -- Actual Flag
                               || '|'   ||lr_ledger_balances.period_name         -- Period
                               || '|'   ||lr_ledger_balances.period_year         -- Year
                               || '|'   ||lr_ledger_balances.currency_code       -- Currency
                               || '|'   ||lr_ledger_balances.company             -- Company
                               || '|'   ||lr_ledger_balances.acct_parent         -- Parent Account
                               || '|'   ||lr_ledger_balances.segment3            -- Account
                               || '|'   ||lr_ledger_balances.acct_description    -- Account Description
                               || '|'   ||lr_ledger_balances.cc_parent           -- Parent Cost Center -- Defect 9274
                               || '|'   ||lr_ledger_balances.segment2            -- Cost Center
                               || '|'   ||lr_ledger_balances.segment4            -- Location
                               || '|'   ||lr_ledger_balances.segment6            -- LOB
                               || '|'   ||lr_ledger_balances.net_bal_mtd         -- NET MTD Balance
                               );
           EXCEPTION
              WHEN OTHERS THEN
                  ln_error_flag := 1;
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while writing into Text file for excluded company for MTD balances '|| SQLERRM);
           END;
/*****************R 1.4 CR 634 QC DefectID#6428 Fix****************Ends****************/

   END LOOP;

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Company: ' || lc_previous_company ||'  Number of rows extracted: '||ln_com_count);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'----------- Excluded Company  --------------------------------------------------');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Set of Books: ' || p_sob_name || ' Period: ' || p_period_name ||' Currency: '||'CAD'|| ' Total Posted Amount  : ' || ln_sob_ytd_bal_cad);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Set of Books: ' || p_sob_name || ' Period: ' || p_period_name ||' Currency: '||'USD'|| ' Total Posted Amount  : ' || ln_sob_ytd_bal_usd);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Set of Books: ' || p_sob_name || ' Period: ' || p_period_name ||' Currency: '||'STAT'|| ' Total Posted Amount : ' || ln_sob_ytd_bal_stat);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'---------------------------------------------------------------------------------');
/*****************R 1.4 CR 634 QC DefectID#6428 Fix****************Start****************/
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'----------- Excluded Company for MTD balances --------------------------------------------------');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Set of Books: ' || p_sob_name || ' Period: ' || p_period_name ||' Currency: '||'CAD'|| ' Total Posted Amount  : ' || ln_sob_mtd_bal_cad);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Set of Books: ' || p_sob_name || ' Period: ' || p_period_name ||' Currency: '||'USD'|| ' Total Posted Amount  : ' || ln_sob_mtd_bal_usd);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Set of Books: ' || p_sob_name || ' Period: ' || p_period_name ||' Currency: '||'STAT'|| ' Total Posted Amount : ' || ln_sob_mtd_bal_stat);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'---------------------------------------------------------------------------------');

/*****************R 1.4 CR 634 QC DefectID#6428 Fix****************Ends****************/

 --------  Writing Into File For Non-Excluded Company    --------
      lc_previous_company := NULL;
      ln_com_count := 0;
      ln_sob_ytd_bal_cad := 0;
      ln_sob_ytd_bal_usd := 0;
      ln_sob_ytd_bal_stat := 0;

/*****************R 1.4 CR 634 QC DefectID#6428 Fix****************Start****************/

 --------  Writing Into File For Non-Excluded Company  for MTD balances  --------
      ln_sob_mtd_bal_cad := 0;
      ln_sob_mtd_bal_usd := 0;
      ln_sob_mtd_bal_stat := 0;

/*****************R 1.4 CR 634 QC DefectID#6428 Fix****************Ends****************/

 --------Fetching value for Scenario from translation --------
  BEGIN
    SELECT XFTV.target_value1
    INTO lc_scenario_non_exld
    FROM xx_fin_translatedefinition  XFTD
        ,xx_fin_translatevalues      XFTV
    WHERE XFTV.translate_id = XFTD.translate_id
    AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
    AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
    AND XFTV.source_value1 = 'Scenario'
    AND XFTD.translation_name = 'XX_GL_1360_BALANCE_EXT'
    AND XFTV.enabled_flag = 'Y'
    AND XFTD.enabled_flag = 'Y';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'No values found for Scenario from translation   ');
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching values from translation for Scenario    '
                                      || SQLERRM);
  END;

  -------- Fetching value for Layer from translation --------
  BEGIN
    SELECT XFTV.target_value1
    INTO lc_layer_non_exld
    FROM xx_fin_translatedefinition  XFTD
        ,xx_fin_translatevalues      XFTV
    WHERE XFTV.translate_id = XFTD.translate_id
    AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
    AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
    AND XFTV.source_value1 = 'Layer'
    AND XFTD.translation_name = 'XX_GL_1360_BALANCE_EXT'
    AND XFTV.enabled_flag = 'Y'
    AND XFTD.enabled_flag = 'Y';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'No values found for Layer from translation ');
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching values from translation for Layer    '
                                      || SQLERRM);
  END;

   FOR lr_ledger_balances IN lcu_ledger_non_excl
   LOOP
      IF(lc_previous_company <> lr_ledger_balances.COMPANY) THEN
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Company: ' || lc_previous_company ||'  Number of rows extracted: '||ln_com_count);
         ln_com_count := 0;
      END IF;
         ln_com_count := ln_com_count+1;
         lc_previous_company := lr_ledger_balances.COMPANY;

   -------- Opening the Non Excluded File   --------
      IF NOT UTL_FILE.is_open(lt_file_non_exld) THEN
       BEGIN
         lt_file_non_exld := UTL_FILE.fopen(lc_file_path,p_non_excluded_file,'w',ln_buffer);
         lc_file_flag_non_exld := 'Y';
       EXCEPTION
         WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised while Opening the Non Excluded file. '|| SQLERRM);
       END;
      END IF;

/*****************R 1.4 CR 634 QC DefectID#6428 Fix****************Start****************/

   -------- Opening the Non Excluded File   --------
      IF NOT UTL_FILE.is_open(lt_file_non_exld_mtd) THEN
       BEGIN
         lt_file_non_exld_mtd := UTL_FILE.fopen(lc_file_path,p_non_excluded_file_mtd,'w',ln_buffer);
         lc_file_flag_non_exld := 'Y';
       EXCEPTION
         WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised while Opening the Non Excluded file for MTD balances. '|| SQLERRM);
       END;
      END IF;
/*****************R 1.4 CR 634 QC DefectID#6428 Fix****************Ends****************/

   -------- Calculation of postal amounts for non Excluded company  --------
      IF(lr_ledger_balances.currency_code = 'CAD') THEN
         ln_sob_ytd_bal_cad  := ln_sob_ytd_bal_cad + lr_ledger_balances.Net_Bal;
      ELSIF(lr_ledger_balances.currency_code = 'USD')THEN
         ln_sob_ytd_bal_usd  := ln_sob_ytd_bal_usd + lr_ledger_balances.Net_Bal;
      ELSE
         ln_sob_ytd_bal_stat := ln_sob_ytd_bal_stat + lr_ledger_balances.Net_Bal;
      END IF;

/*****************R 1.4 CR 634 QC DefectID#6428 Fix****************Start****************/

   -------- Calculation of postal amounts for non Excluded company for MTD balances --------
      IF(lr_ledger_balances.currency_code = 'CAD') THEN
         ln_sob_mtd_bal_cad  := ln_sob_mtd_bal_cad + lr_ledger_balances.net_bal_mtd;
      ELSIF(lr_ledger_balances.currency_code = 'USD')THEN
         ln_sob_mtd_bal_usd  := ln_sob_mtd_bal_usd + lr_ledger_balances.net_bal_mtd;
      ELSE
         ln_sob_mtd_bal_stat := ln_sob_mtd_bal_stat + lr_ledger_balances.net_bal_mtd;
      END IF;

/*****************R 1.4 CR 634 QC DefectID#6428 Fix****************Ends****************/


   -------- Assigning Scenario and layer Values for Non Excluded company  --------

         lc_scenario_print := NVL(lr_ledger_balances.Scenario,lc_scenario_non_exld);
         lc_layer_print    := NVL(lr_ledger_balances.layer,lc_layer_non_exld);

   -------- Writing GL Balances into text file for non excluded company  ---------
           BEGIN
              UTL_FILE.PUT_LINE(lt_file_non_exld,lc_scenario_print                 -- Scenario
                               || '|'   ||lr_ledger_balances.period                -- Period
                               || '|'   ||'FY'||lr_ledger_balances.year            -- Year
                               || '|'   ||lr_ledger_balances.company               -- Company
                               || '|'   ||lr_ledger_balances.segment3              -- Account
                               || '|'   ||lr_ledger_balances.segment2              -- Cost Center
                               || '|'   ||lr_ledger_balances.segment6              -- LOB
                               || '|'   ||lr_ledger_balances.segment4              -- Location
                               || '|'   ||lr_ledger_balances.currency_code         -- Currency
                               || '|'   ||lc_layer_print                           -- Layer
                               || '|'   ||lr_ledger_balances.net_bal               -- NET YTD Balance(Amount)
                         );
           EXCEPTION
              WHEN OTHERS THEN
              ln_error_flag := 1;
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while writing into Text file for non excluded company'|| SQLERRM);
           END;

/*****************R 1.4 CR 634 QC DefectID#6428 Fix****************Start****************/

              -------- Writing GL Balances into text file for non excluded company  ---------
           BEGIN
              UTL_FILE.PUT_LINE(lt_file_non_exld_mtd,lc_scenario_print             -- Scenario
                               || '|'   ||lr_ledger_balances.period                -- Period
                               || '|'   ||'FY'||lr_ledger_balances.year            -- Year
                               || '|'   ||lr_ledger_balances.company               -- Company
                               || '|'   ||lr_ledger_balances.segment3              -- Account
                               || '|'   ||lr_ledger_balances.segment2              -- Cost Center
                               || '|'   ||lr_ledger_balances.segment6              -- LOB
                               || '|'   ||lr_ledger_balances.segment4              -- Location
                               || '|'   ||lr_ledger_balances.currency_code         -- Currency
                               || '|'   ||lc_layer_print                           -- Layer
                               || '|'   ||lr_ledger_balances.net_bal_mtd           -- NET MTD Balance(Amount)
                         );
           EXCEPTION
              WHEN OTHERS THEN
              ln_error_flag := 1;
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while writing into Text file for non excluded company for MTD balances'|| SQLERRM);
           END;

/*****************R 1.4 CR 634 QC DefectID#6428 Fix****************Ends****************/
   END LOOP;

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Company: ' || lc_previous_company ||'  Number of rows extracted: '||ln_com_count);
      lc_previous_company := NULL;
      ln_com_count := 0;

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'----------- Non-Excluded Company  --------------------------------------------------');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Set of Books: ' || p_sob_name || ' Period: ' || p_period_name ||' Currency: '||'CAD'|| ' Total Posted Amount  : ' || ln_sob_ytd_bal_cad);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Set of Books: ' || p_sob_name || ' Period: ' || p_period_name ||' Currency: '||'USD'|| ' Total Posted Amount  : ' || ln_sob_ytd_bal_usd);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Set of Books: ' || p_sob_name || ' Period: ' || p_period_name ||' Currency: '||'STAT'|| ' Total Posted Amount : ' || ln_sob_ytd_bal_stat);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'---------------------------------------------------------------------------------');

/*****************R 1.4 CR 634 QC DefectID#6428 Fix****************Start****************/


      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'----------- Non-Excluded Company for MTD balances --------------------------------------------------');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Set of Books: ' || p_sob_name || ' Period: ' || p_period_name ||' Currency: '||'CAD'|| ' Total Posted Amount  : ' || ln_sob_mtd_bal_cad);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Set of Books: ' || p_sob_name || ' Period: ' || p_period_name ||' Currency: '||'USD'|| ' Total Posted Amount  : ' || ln_sob_mtd_bal_usd);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Set of Books: ' || p_sob_name || ' Period: ' || p_period_name ||' Currency: '||'STAT'|| ' Total Posted Amount : ' || ln_sob_mtd_bal_stat);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'---------------------------------------------------------------------------------');

/*****************R 1.4 CR 634 QC DefectID#6428 Fix****************Ends****************/

   -------- Closing the Excluded and Non Excluded Company Files --------
      IF UTL_FILE.is_open(lt_file_non_exld)
      THEN
        UTL_FILE.fclose(lt_file_non_exld);
      END IF;
      IF UTL_FILE.is_open(lt_file_excluded)
      THEN
        UTL_FILE.fclose(lt_file_excluded);
      END IF;

/*****************R 1.4 CR 634 QC DefectID#6428 Fix****************Start****************/

   -------- Closing the Excluded and Non Excluded Company Files for MTD balances--------
      IF UTL_FILE.is_open(lt_file_non_exld_mtd)
      THEN
        UTL_FILE.fclose(lt_file_non_exld_mtd);
      -- Added for Defect # 10225 -- Start
      END IF;
      IF UTL_FILE.is_open(lt_file_excluded_mtd)
      THEN
        UTL_FILE.fclose(lt_file_excluded_mtd);
      END IF;
      -- Added for Defect # 10225 -- End

	-- Commented for Defect # 10225 -- Start
	/*
	ELSIF UTL_FILE.is_open(lt_file_excluded_mtd)
      THEN
        UTL_FILE.fclose(lt_file_excluded_mtd);
      END IF;
	*/
	-- Commented for Defect # 10225 -- End

/*****************R 1.4 CR 634 QC DefectID#6428 Fix****************Ends****************/

     IF ln_error_flag = 0 THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'The GL Balances have been written into the file successfully.');
     END IF;

   --------- Call the Common file copy Program to archive the file into $XXFIN_ARCHIVE/outbound -------

  lc_source_file_excluded   := lc_source_file_path  || '/' || p_file_name;
  lc_dest_file_excluded     := lc_archive_file_path || '/' || SUBSTR(p_file_name,1,LENGTH(p_file_name) - 4)
                                                           || TO_CHAR(SYSDATE, 'DD-MON-YYYYHHMMSS') || '.txt';
  lc_source_file_name       := lc_source_file_path  || '/' || p_non_excluded_file;
  lc_dest_file_name         := lc_archive_file_path || '/' || SUBSTR(p_non_excluded_file,1,LENGTH(p_non_excluded_file) - 4)
                                                           || TO_CHAR(SYSDATE, 'DD-MON-YYYYHHMMSS') || '.txt';

/*****************R 1.4 CR 634 QC DefectID#6428 Fix****************Start****************/

   --------- Call the Common file copy Program to archive the file into $XXFIN_ARCHIVE/outbound for MTD balances -------

  lc_source_file_excluded_mtd   := lc_source_file_path  || '/' || p_excluded_file_mtd;
  lc_dest_file_excluded_mtd     := lc_archive_file_path || '/' || SUBSTR(p_excluded_file_mtd,1,LENGTH(p_excluded_file_mtd) - 4)
                                                           || TO_CHAR(SYSDATE, 'DD-MON-YYYYHHMMSS') || '.txt';
  lc_source_file_name_mtd       := lc_source_file_path  || '/' || p_non_excluded_file_mtd;
  lc_dest_file_name_mtd         := lc_archive_file_path || '/' || SUBSTR(p_non_excluded_file_mtd,1,LENGTH(p_non_excluded_file_mtd) - 4)
                                                           || TO_CHAR(SYSDATE, 'DD-MON-YYYYHHMMSS') || '.txt';

/*****************R 1.4 CR 634 QC DefectID#6428 Fix****************Ends****************/


  FND_FILE.PUT_LINE(FND_FILE.LOG,'*************************************************************');
  --FND_FILE.PUT_LINE(FND_FILE.LOG,'');
  FND_FILE.PUT_LINE(FND_FILE.LOG,'The Created File Name for non excluded company                   : ' || lc_source_file_name);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'The Archived File Path for non excluded company                  : ' || lc_dest_file_name);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'The Created File Name for excluded company                       : ' || lc_source_file_excluded);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'The Archived File Path for excluded company                      : ' || lc_dest_file_excluded);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'');
  FND_FILE.PUT_LINE(FND_FILE.LOG,'The Created File Name for non excluded company for MTD balances  : ' || lc_source_file_name_mtd);      -- Added for R 1.4 CR 634 QC 6428 Fix
  FND_FILE.PUT_LINE(FND_FILE.LOG,'The Archived File Path for non excluded company for MTD balances : ' || lc_dest_file_name_mtd);        -- Added for R 1.4 CR 634 QC 6428 Fix
  FND_FILE.PUT_LINE(FND_FILE.LOG,'The Created File Name for excluded company for MTD balances      : ' || lc_source_file_excluded_mtd);  -- Added for R 1.4 CR 634 QC 6428 Fix
  FND_FILE.PUT_LINE(FND_FILE.LOG,'The Archived File Path for excluded company for MTD balances     : ' || lc_dest_file_excluded_mtd);    -- Added for R 1.4 CR 634 QC 6428 Fix
  FND_FILE.PUT_LINE(FND_FILE.LOG,'');
  --FND_FILE.PUT_LINE(FND_FILE.LOG,'*************************************************************');

  -------- Submitting the common file copy program for Excluded company file  --------
  IF (lc_file_flag_exld = 'Y') THEN

  ln_req_id_exld := FND_REQUEST.SUBMIT_REQUEST ('xxfin'
                                              ,'XXCOMFILCOPY'
                                              ,''
                                              ,''
                                              ,FALSE
                                              ,lc_source_file_excluded
                                              ,lc_dest_file_excluded
                                              ,NULL
                                              ,NULL
                                              );
  FND_FILE.PUT_LINE(FND_FILE.LOG,'The Excluded File was Archived into ' ||  lc_archive_file_path
                                            || '  **** Request id ****  ' || ln_req_id_exld);

COMMIT;
   --------- Wait for the Common file copy Program to Complete for Excluded Company file  --------
  lb_req_status_exld := FND_CONCURRENT.WAIT_FOR_REQUEST(request_id  => ln_req_id_exld
                                                        ,interval    => '2'
                                                        ,max_wait    => ''
                                                        ,phase       => lc_phase
                                                        ,status      => lc_status
                                                        ,dev_phase   => lc_devphase
                                                        ,dev_status  => lc_devstatus
                                                        ,message     => lc_message
                                                        );

/*****************R 1.4 CR 634 QC DefectID#6428 Fix****************Start****************/

  ln_req_id_exld_mtd := FND_REQUEST.SUBMIT_REQUEST ('xxfin'
                                              ,'XXCOMFILCOPY'
                                              ,''
                                              ,''
                                              ,FALSE
                                              ,lc_source_file_excluded_mtd
                                              ,lc_dest_file_excluded_mtd
                                              ,NULL
                                              ,NULL
                                              );
  FND_FILE.PUT_LINE(FND_FILE.LOG,'The Excluded File for MTD balances was Archived into ' ||  lc_archive_file_path
                                            || '  **** Request id ****  ' || ln_req_id_exld_mtd);

/*****************R 1.4 CR 634 QC DefectID#6428 Fix****************Ends****************/

  COMMIT;

/*****************R 1.4 CR 634 QC DefectID#6428 Fix****************Start****************/
   --------- Wait for the Common file copy Program to Complete for Excluded Company file for MTD balances --------

  lb_req_status_exld_mtd := FND_CONCURRENT.WAIT_FOR_REQUEST(request_id  => ln_req_id_exld_mtd
                                                        ,interval    => '2'
                                                        ,max_wait    => ''
                                                        ,phase       => lc_phase
                                                        ,status      => lc_status
                                                        ,dev_phase   => lc_devphase
                                                        ,dev_status  => lc_devstatus
                                                        ,message     => lc_message
                                                        );

/*****************R 1.4 CR 634 QC DefectID#6428 Fix****************Ends****************/

  END IF;

    -- Submitting the common file copy program for Non Excluded Company File   --------
  IF (lc_file_flag_non_exld='Y')
  THEN
     ln_req_id := FND_REQUEST.SUBMIT_REQUEST ('xxfin'
                                             ,'XXCOMFILCOPY'
                                             ,''
                                             ,''
                                             ,FALSE
                                             ,lc_source_file_name
                                             ,lc_dest_file_name
                                             ,NULL
                                             ,NULL
                                            );

     FND_FILE.PUT_LINE(FND_FILE.LOG,'The Non Excluded File was Archived into ' ||  lc_archive_file_path
                                         || ' ****Request id**** '  || ln_req_id);
COMMIT;

  --------- Wait for the Common file copy Program to Complete for Non Excluded Company file  --------
  lb_req_status := FND_CONCURRENT.WAIT_FOR_REQUEST(request_id  => ln_req_id
                                                   ,interval    => '2'
                                                   ,max_wait    => ''
                                                   ,phase       => lc_phase
                                                   ,status      => lc_status
                                                   ,dev_phase   => lc_devphase
                                                   ,dev_status  => lc_devstatus
                                                   ,message     => lc_message
                                                  );


/*****************R 1.4 CR 634 QC DefectID#6428 Fix****************Start****************/

     ln_req_id_mtd := FND_REQUEST.SUBMIT_REQUEST ('xxfin'
                                             ,'XXCOMFILCOPY'
                                             ,''
                                             ,''
                                             ,FALSE
                                             ,lc_source_file_name_mtd
                                             ,lc_dest_file_name_mtd
                                             ,NULL
                                             ,NULL
                                            );

     FND_FILE.PUT_LINE(FND_FILE.LOG,'The Non Excluded File for MTD balances was Archived into ' ||  lc_archive_file_path
                                         || ' ****Request id**** '  || ln_req_id_mtd);

/*****************R 1.4 CR 634 QC DefectID#6428 Fix****************Ends****************/
  COMMIT;
/*****************R 1.4 CR 634 QC DefectID#6428 Fix****************Start****************/

  --------- Wait for the Common file copy Program to Complete for Non Excluded Company file for MTD balances  --------
  lb_req_status_mtd := FND_CONCURRENT.WAIT_FOR_REQUEST(request_id  => ln_req_id_mtd
                                                   ,interval    => '2'
                                                   ,max_wait    => ''
                                                   ,phase       => lc_phase
                                                   ,status      => lc_status
                                                   ,dev_phase   => lc_devphase
                                                   ,dev_status  => lc_devstatus
                                                   ,message     => lc_message
                                                  );

/*****************R 1.4 CR 634 QC DefectID#6428 Fix****************Ends****************/

  END IF;

END write_to_file;

/*****************  Discarded Old Write_to_File Procedure
                ---  for R 1.2 CR 745 QC 2841 Fix
********************************/
-- +====================================================================+
-- | Name : WRITE_TO_FILE                                               |
-- | Description : Extracts Ledger Balances for a given Period and      |
-- |               Set of Books and writes them into a .txt file and    |
-- |               archives the file                                    |
-- | Parameters :  p_file_name, p_source_file_path, p_set_of_books_id,  |
-- |               p_sob_name, p_coa_id, p_currency_code, p_period_name,|
-- |               p_appl_id                                            |
-- +====================================================================+

/*PROCEDURE WRITE_TO_FILE(p_file_name             IN VARCHAR2
                        ,p_source_file_path     IN VARCHAR2
                        ,p_set_of_books_id      IN NUMBER
                        ,p_sob_name             IN VARCHAR2
                        ,p_coa_id               IN NUMBER
                        ,p_currency_code        IN VARCHAR2
                        ,p_period_name          IN VARCHAR2
                        ,p_appl_id              IN NUMBER
                        ,p_acc_rolup_grp_name   IN VARCHAR2
                        ,p_cc_rolup_grp_name    IN VARCHAR2
                        )
IS
  lb_req_status        BOOLEAN;
  lc_file_path         VARCHAR2(500) := 'XXFIN_DAILY';
  lc_source_file_path  VARCHAR2(500) ;
  lc_dest_file_path    VARCHAR2(500) := '$XXFIN_DATA/ftp/out/hyperion';
  lc_archive_file_path VARCHAR2(500) := '$XXFIN_ARCHIVE/outbound';
  lc_source_file_name  VARCHAR2(1000);
  lc_dest_file_name    VARCHAR2(1000);
  lc_phase             VARCHAR2(50);
  lc_status            VARCHAR2(50);
  lc_devphase          VARCHAR2(50);
  lc_devstatus         VARCHAR2(50);
  lc_message           VARCHAR2(50);
  lc_error_msg         VARCHAR2(4000);
  ln_req_id            NUMBER(10);
  ln_msg_cnt           NUMBER := 0;
  ln_cc_value_set_id   NUMBER; -- Defect 9274
  ln_acct_value_set_id NUMBER;
  lt_file              UTL_FILE.FILE_TYPE;
  ln_buffer            BINARY_INTEGER := 32767;
  ln_appl_id           fnd_application.application_id%TYPE;
  ln_sob_ytd_bal_cad       NUMBER := 0;                            -- Added for Defect 11192
  ln_sob_ytd_bal_usd       NUMBER := 0;                            -- Added for Defect 11192
  ln_sob_ytd_bal_stat      NUMBER := 0;                            -- Added for Defect 11192
  ln_com_count         NUMBER :=0;
  lc_previous_company  gl_code_combinations.segment1%TYPE := NULL;
  ln_acc_rollup_grp    NUMBER;
  ln_cc_rollup_grp     NUMBER;
  ln_error_flag        NUMBER := 0;
  lc_parent_acc        CONSTANT fnd_flex_value_norm_hierarchy.parent_flex_value%TYPE := 'P8000000'; -- Defect 9274

  --------Cursor Query for extracting GL Balances---------
  CURSOR lcu_ledger_balances(p_acct_value_set_id IN NUMBER
                            ,p_cc_value_set_id   IN NUMBER
                            ,p_acc_rollup_grp    IN NUMBER -- Defect 9274
                            ,p_cc_rollup_grp     IN NUMBER -- Defect 9274
                            ,p_coa_id            IN NUMBER)
  IS
-- Start changes for defect - 9274
--Query to fetch the records where the parents exist for both account and cost center
  SELECT GLB.period_name
         ,GLB.actual_flag
         ,GLB.period_year
         ,GCC.segment1    COMPANY
         ,GCC.segment2
         ,GCC.segment3
         ,AC_PAR.parent_flex_value acct_parent
         ,CC_PAR.parent_flex_value cc_parent
         ,AC.description acct_description
         ,GCC.segment4
         ,GCC.segment5
         ,GCC.segment6
         ,GCC.segment7
         ,GLB.currency_code
         ,(begin_balance_dr-begin_balance_cr + period_net_dr-period_net_cr) ytd_bal
  FROM   gl_balances GLB
         ,gl_code_combinations GCC
         ,fnd_flex_values_vl AC
         ,fnd_flex_values_vl AC1
         ,fnd_flex_value_norm_hierarchy AC_PAR
         ,fnd_flex_values_vl CC1
         ,fnd_flex_value_norm_hierarchy CC_PAR
  WHERE  GLB.set_of_books_id       = p_set_of_books_id
  AND    GLB.code_combination_id   = GCC.code_combination_id
  AND    GLB.currency_code IN (p_currency_code, 'STAT')
  AND    GLB.period_name = p_period_name
  AND    GLB.actual_flag = 'A'
  AND    GCC.template_id IS NULL
  AND    GCC.chart_of_accounts_id = p_coa_id
  AND    CC_PAR.parent_flex_value = CC1.flex_value
  AND    CC1.flex_value_set_id = p_cc_value_set_id
  AND    CC1.structured_hierarchy_level = p_cc_rollup_grp
  AND    CC_PAR.flex_value_set_id = p_cc_value_set_id
  AND    GCC.segment2 BETWEEN CC_PAR.child_flex_value_low AND CC_PAR.child_flex_value_high
  AND    AC_PAR.parent_flex_value = AC1.flex_value
  AND    AC1.flex_value_set_id = p_acct_value_set_id
  AND    AC1.structured_hierarchy_level = p_acc_rollup_grp
  AND    AC.flex_value_set_id = p_acct_value_set_id
  AND    AC_PAR.flex_value_set_id = p_acct_value_set_id
  AND    AC.flex_value BETWEEN AC_PAR.child_flex_value_low AND AC_PAR.child_flex_value_high
  AND    AC.flex_value = gcc.segment3
  AND    AC1.enabled_flag = 'Y'                  -- Uncommented for Defect 11050
  AND    AC.enabled_flag = 'Y'                   -- Uncommented for Defect 11050
  AND    CC1.enabled_flag = 'Y'
  UNION ALL
  --Query to fetch values where account parent does not exist and cost center parent exist
  SELECT GLB.period_name
         ,GLB.actual_flag
         ,GLB.period_year
         ,GCC.segment1    COMPANY
         ,GCC.segment2
         ,GCC.segment3
         ,'' acct_parent
         ,CC_PAR.parent_flex_value cc_parent
         ,AC.description acct_description
         ,GCC.segment4
         ,GCC.segment5
         ,GCC.segment6
         ,GCC.segment7
         ,GLB.currency_code
         ,(begin_balance_dr-begin_balance_cr + period_net_dr-period_net_cr) ytd_bal
  FROM   gl_balances GLB
         ,gl_code_combinations GCC
         ,fnd_flex_values_vl AC
         ,fnd_flex_values_vl CC1
         ,fnd_flex_value_norm_hierarchy CC_PAR
  WHERE  GLB.set_of_books_id       = p_set_of_books_id
  AND    GLB.code_combination_id   = GCC.code_combination_id
  AND    AC.flex_value_set_id = p_acct_value_set_id
  AND    AC.flex_value = GCC.segment3
  AND    AC.enabled_flag = 'Y'                                -- Uncommented for Defect 11050
  AND NOT EXISTS( SELECT 1
                  FROM fnd_flex_value_norm_hierarchy AC_PAR , fnd_flex_values AC1
                  WHERE AC_PAR.flex_value_set_id = p_acct_value_set_id
                  AND GCC.segment3 BETWEEN AC_PAR.child_flex_value_low AND AC_PAR.child_flex_value_high
                  AND AC1.flex_value = AC_PAR.parent_flex_value
                  AND AC1.flex_value_set_id = p_acct_value_set_id
                  AND AC1.structured_hierarchy_level = p_acc_rollup_grp
                  AND AC1.enabled_flag = 'Y'                 -- Uncommented for Defect 11050
                )
  AND    CC_PAR.parent_flex_value = CC1.flex_value
  AND    CC1.flex_value_set_id = p_cc_value_set_id
  AND    CC1.structured_hierarchy_level = p_cc_rollup_grp
  AND    CC_PAR.flex_value_set_id = p_cc_value_set_id
  AND    GCC.segment2 BETWEEN CC_PAR.child_flex_value_low AND CC_PAR.child_flex_value_high
  AND    GLB.currency_code IN (p_currency_code, 'STAT')
  AND    GLB.period_name = p_period_name
  AND    GLB.actual_flag = 'A'
  AND    GCC.template_id IS NULL
  AND    CC1.enabled_flag = 'Y'
  AND    GCC.chart_of_accounts_id = p_coa_id
  UNION ALL
  --Query to fetch records where both cost center parent and account parent do not exist
  SELECT GLB.period_name
         ,GLB.actual_flag
         ,GLB.period_year
         ,GCC.segment1    COMPANY
         ,GCC.segment2
         ,GCC.segment3
         ,'' acct_parent
         ,'' cc_parent
         ,AC.description acct_description
         ,GCC.segment4
         ,GCC.segment5
         ,GCC.segment6
         ,GCC.segment7
         ,GLB.currency_code
         ,(begin_balance_dr-begin_balance_cr + period_net_dr-period_net_cr) ytd_bal
  FROM   gl_balances GLB
        ,gl_code_combinations GCC
        ,fnd_flex_values_vl AC
  WHERE  GLB.set_of_books_id       = p_set_of_books_id
  AND    GLB.code_combination_id   = GCC.code_combination_id
  AND    AC.flex_value_set_id = p_acct_value_set_id
  AND    AC.flex_value = gcc.segment3
  AND    AC.enabled_flag = 'Y'                              -- Uncommented for Defect 11050
  AND NOT EXISTS( SELECT 1
                  FROM fnd_flex_value_norm_hierarchy AC_PAR , fnd_flex_values AC1
                  WHERE AC_PAR.flex_value_set_id = p_acct_value_set_id
                  AND GCC.segment3 BETWEEN AC_PAR.child_flex_value_low AND AC_PAR.child_flex_value_high
                  AND AC1.flex_value = AC_PAR.parent_flex_value
                  AND AC1. flex_value_set_id = p_acct_value_set_id
                  AND AC1.structured_hierarchy_level = p_acc_rollup_grp
                  AND AC1.enabled_flag = 'Y'                -- Uncommented for Defect 11050
                )
  AND NOT EXISTS( SELECT 1
                  FROM fnd_flex_value_norm_hierarchy CC_PAR, fnd_flex_values CC1
                  WHERE CC_PAR.flex_value_set_id = p_cc_value_set_id
                  AND GCC.segment2 BETWEEN CC_PAR.child_flex_value_low AND CC_PAR.child_flex_value_high
                  AND CC1.flex_value = CC_PAR.parent_flex_value
                  AND CC1. flex_value_set_id = p_cc_value_set_id
                  AND CC1.structured_hierarchy_level = p_cc_rollup_grp
                  AND CC1.enabled_flag = 'Y'
                )
  AND    GLB.currency_code IN (p_currency_code, 'STAT')
  AND    GLB.period_name = p_period_name
  AND    GLB.actual_flag = 'A'
  AND    GCC.template_id IS NULL
  AND    GCC.chart_of_accounts_id = p_coa_id
  UNION ALL
 --Query to fetch the records where parent account exists but parent cost center does not exist
  SELECT GLB.period_name
         ,GLB.actual_flag
         ,GLB.period_year
         ,GCC.segment1    COMPANY
         ,GCC.segment2
         ,GCC.segment3
         ,AC_PAR.parent_flex_value acct_parent
         ,'' cc_parent
         ,AC.description acct_description
         ,GCC.segment4
         ,GCC.segment5
         ,GCC.segment6
         ,GCC.segment7
         ,GLB.currency_code
         ,(begin_balance_dr-begin_balance_cr + period_net_dr-period_net_cr) ytd_bal
  FROM   gl_balances GLB
         ,gl_code_combinations GCC
         ,fnd_flex_values_vl AC
         ,fnd_flex_values_vl AC1
         ,fnd_flex_value_norm_hierarchy AC_PAR
  WHERE  GLB.set_of_books_id       = p_set_of_books_id
  AND    GLB.code_combination_id   = GCC.code_combination_id
  AND    AC_PAR.parent_flex_value = AC1.flex_value
  AND    AC1.flex_value_set_id = p_acct_value_set_id
  AND    AC1.structured_hierarchy_level = p_acc_rollup_grp
  AND    AC.flex_value_set_id = p_acct_value_set_id
  AND    AC_PAR.flex_value_set_id = p_acct_value_set_id
  AND    AC.flex_value BETWEEN AC_PAR.child_flex_value_low AND AC_PAR.child_flex_value_high
  AND    AC.flex_value = gcc.segment3
  AND    AC.enabled_flag = 'Y'                           -- Uncommented for Defect 11050
  AND    AC1.enabled_flag = 'Y'                          -- Uncommented for Defect 11050
  AND NOT EXISTS( SELECT 1
                  FROM fnd_flex_value_norm_hierarchy CC_PAR, fnd_flex_values CC1
                  WHERE CC_PAR.flex_value_set_id = p_cc_value_set_id
                  AND   GCC.segment2 BETWEEN CC_PAR.child_flex_value_low AND CC_PAR.child_flex_value_high
                  AND   CC1.flex_value = CC_PAR.parent_flex_value
                  AND   CC1. flex_value_set_id = p_cc_value_set_id
                  AND   CC1.structured_hierarchy_level = p_cc_rollup_grp
                  AND   CC1.enabled_flag = 'Y'
                )
  AND    GLB.currency_code IN (p_currency_code, 'STAT')
  AND    GLB.period_name = p_period_name
  AND    GLB.actual_flag = 'A'
  AND    GCC.template_id IS NULL
  AND    GCC.chart_of_accounts_id = p_coa_id
  ORDER BY COMPANY;
-- End changes for defect - 9274
/*  SELECT GLB.period_name
         ,GLB.actual_flag
         ,GLB.period_year
         ,GLB.currency_code
         ,GCC.segment1    COMPANY
         ,GCC.segment2
         ,GCC.segment3
         ,AC_PAR.parent_flex_value acct_parent
         ,CC_PAR.parent_flex_value cc_parent -- Defect 9274
         ,AC.description acct_description
         ,GCC.segment4
         ,GCC.segment5
         ,GCC.segment6
         ,GCC.segment7
         ,(begin_balance_dr-begin_balance_cr + period_net_dr-period_net_cr) ytd_bal
  FROM   (fnd_flex_value_norm_hierarchy AC_PAR RIGHT OUTER JOIN fnd_flex_values_vl AC
         ON AC_PAR.flex_value_set_id = p_acct_value_set_id
            AND SYSDATE BETWEEN (NVL(AC_PAR.start_date_active,SYSDATE)) AND (NVL(AC_PAR.start_date_active,SYSDATE)) -- Defect 9274
            AND AC.flex_value BETWEEN AC_PAR.child_flex_value_low AND AC_PAR.child_flex_value_high
            AND AC.enabled_flag = 'Y' -- Defect 9274
            AND SYSDATE BETWEEN (NVL(AC.start_date_active,SYSDATE)) AND (NVL(AC.start_date_active,SYSDATE))) -- Defect 9274
         LEFT OUTER JOIN fnd_flex_values_vl AC1 -- Defect 9274
            ON AC_PAR.flex_value_set_id = p_acct_value_set_id -- Defect 9274
            --AND AC_PAR.flex_value_set_id IS NULL -- Defect 9274
            AND AC_PAR.parent_flex_value = AC1.flex_value -- Defect 9274
            AND AC1.structured_hierarchy_level = p_acc_rollup_grp -- Defect 9274
         ,(fnd_flex_value_norm_hierarchy CC_PAR RIGHT OUTER JOIN fnd_flex_values_vl CC -- Defect 9274
          ON CC_PAR.flex_value_set_id = p_cc_value_set_id
             AND SYSDATE BETWEEN (NVL(CC_PAR.start_date_active,SYSDATE)) AND (NVL(CC_PAR.start_date_active,SYSDATE)) -- Defect 9274
             AND CC.flex_value BETWEEN CC_PAR.child_flex_value_low AND CC_PAR.child_flex_value_high
             AND CC.enabled_flag = 'Y' -- Defect 9274
             AND SYSDATE BETWEEN (NVL(CC.start_date_active,SYSDATE)) AND (NVL(CC.start_date_active,SYSDATE))) -- Defect 9274
          LEFT OUTER JOIN fnd_flex_values_vl CC1 -- Defect 9274
             ON CC_PAR.flex_value_set_id = p_cc_value_set_id -- Defect 9274
           --  AND CC_PAR.flex_value_set_id IS NULL -- Defect 9274
             AND CC_PAR.parent_flex_value = CC1.flex_value -- Defect 9274
             -- Defect 9274
         ,gl_code_combinations GCC
         ,gl_balances GLB
  WHERE  GLB.set_of_books_id = p_set_of_books_id
  AND    GLB.currency_code IN (p_currency_code, 'STAT')
  AND    GLB.period_name = p_period_name
  AND    GLB.actual_flag = 'A'
  AND    GCC.template_id IS NULL
  AND    GCC.chart_of_accounts_id = p_coa_id
  AND    AC.flex_value_set_id = p_acct_value_set_id
  AND    CC.flex_value_set_id = p_cc_value_set_id -- Defect 9274
  AND    GLB.code_combination_id   = GCC.code_combination_id
  AND    AC.flex_value = gcc.segment3
  AND    CC.flex_value = gcc.segment2 -- Defect 9274
  ORDER BY COMPANY;*/
--  AND    CC_PAR.flex_value_set_id = p_cc_value_set_id
--  AND    CC.flex_value BETWEEN CC_PAR.child_flex_value_low AND CC_PAR.child_flex_value_high
--  AND    AC_PAR.flex_value_set_id = p_acct_value_set_id
--  AND    AC.flex_value BETWEEN AC_PAR.child_flex_value_low AND AC_PAR.child_flex_value_high
/*  UNION ALL
  SELECT GLB.period_name
         ,GLB.actual_flag
         ,GLB.period_year
         ,GCC.segment1    COMPANY
         ,GCC.segment2
         ,GCC.segment3
         ,'-' acct_parent
--         ,CC_PAR.parent_flex_value cc_parent
         ,AC.description acct_description
         ,GCC.segment4
         ,GCC.segment5
         ,GCC.segment6
         ,GCC.segment7
         ,GLB.currency_code
         ,(begin_balance_dr-begin_balance_cr + period_net_dr-period_net_cr) ytd_bal
  FROM   gl_balances GLB
         ,gl_code_combinations GCC
         ,fnd_flex_values_vl AC
        -- ,fnd_flex_value_norm_hierarchy AC_PAR
--         ,fnd_flex_values_vl CC
--         ,fnd_flex_value_norm_hierarchy CC_PAR
  WHERE  GLB.set_of_books_id       = p_set_of_books_id
  AND    GLB.code_combination_id   = GCC.code_combination_id
  AND    AC.flex_value_set_id = p_acct_value_set_id
  AND    AC.flex_value = gcc.segment3
  AND NOT EXISTS( SELECT 1
                  FROM fnd_flex_value_norm_hierarchy AC_PAR
                  WHERE AC_PAR.flex_value_set_id = p_acct_value_set_id
                  AND AC.flex_value BETWEEN AC_PAR.child_flex_value_low AND AC_PAR.child_flex_value_high
                )
  AND    GLB.currency_code IN (p_currency_code, 'STAT')
  AND    GLB.period_name = p_period_name
  AND    GLB.actual_flag = 'A'
  AND    GCC.template_id IS NULL
  AND    GCC.chart_of_accounts_id = p_coa_id
  ORDER BY COMPANY;*/

  --------Cursor Query for counting the number of rows extracted per Company---------
/*  CURSOR lcu_ledger_bal_rec_num
  IS
  SELECT segment1
         ,COUNT(1) cnt
  FROM   (SELECT GLB.period_name
                 ,GLB.actual_flag
                 ,GLB.period_year
                 ,GCC.segment1
                 ,GCC.segment2
                 ,GCC.segment3
                 ,GCC.segment4
                 ,GCC.segment5
                 ,GCC.segment6
                 ,GCC.segment7
                 ,GLB.currency_code
          FROM   gl_balances GLB
                 ,gl_code_combinations GCC
          WHERE   GLB.set_of_books_id       = p_set_of_books_id
          AND     GLB.code_combination_id   = GCC.code_combination_id
          AND     GLB.currency_code IN (p_currency_code, 'STAT')
          AND     GLB.period_name = p_period_name
          AND     GLB.actual_flag = 'A'
          AND     GCC.template_id IS NULL)
  GROUP BY segment1;

  BEGIN

  lc_source_file_path := p_source_file_path;
  ln_appl_id := p_appl_id;

  FND_FILE.PUT_LINE(FND_FILE.LOG,'*************************************************************');
  FND_FILE.PUT_LINE(FND_FILE.LOG,'SOB Name     : ' || p_sob_name);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Currency     : ' || p_currency_code);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Period Name  : ' || p_period_name);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'-------------------------------------------------------------');

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'*************************************************************');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'SOB Name      : ' || p_sob_name);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Currency      : ' || p_currency_code);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Period Name   : ' || p_period_name);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------------------------');

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The GL Balance Extract File Name : ' || p_file_name);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'The Created File Path               : ' || lc_file_path);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'The Destination File Path           : ' || lc_dest_file_path);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'*************************************************************');

  BEGIN
    lt_file := UTL_FILE.fopen(lc_file_path, p_file_name,'w',ln_buffer);
  EXCEPTION
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised while Opening the file. '|| SQLERRM);
  END;

  --------Query for fetching flex_value_set_ids for Accounts and Cost Centers---------
  BEGIN

    SELECT FFV_CC.flex_value_set_id -- Defect 9274
           ,FFV_AC.flex_value_set_id
    INTO   ln_cc_value_set_id -- Defect 9274
           ,ln_acct_value_set_id
    FROM   fnd_flex_value_sets FFV_CC -- Defect 9274
           ,fnd_id_flex_segments FSG_CC -- Defect 9274
           ,fnd_flex_value_sets FFV_AC
           ,fnd_id_flex_segments FSG_AC
    WHERE  FSG_CC.segment_name = 'Cost Center' -- Defect 9274
    AND    FSG_CC.flex_value_set_id = FFV_CC.flex_value_set_id -- Defect 9274
    AND    FSG_CC.id_flex_num = p_coa_id -- Defect 9274
    AND    FSG_AC.segment_name = 'Account'
    AND    FSG_AC.id_flex_num = p_coa_id
    AND    FSG_AC.flex_value_set_id = FFV_AC.flex_value_set_id;

  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Value Set IDs not found for Account and Cost Center. '
                                    || SQLERRM);
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching Value Set IDs for Account and Cost Center. '
                                    || SQLERRM);
  END;

  -- Start changes for Defect 9274
  --------Query for fetching hierarchy_id for Report Line    ---------
  BEGIN

    SELECT ACC.hierarchy_id
    INTO   ln_acc_rollup_grp
    FROM   fnd_flex_hierarchies_vl ACC
    WHERE  ACC.hierarchy_code = p_acc_rolup_grp_name
    AND    ACC.flex_value_set_id = ln_acct_value_set_id;

  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Hierarchy IDs not found for Report Line. '
                                    || SQLERRM);
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching Hierarchy IDs not found for Report Line. '
                                    || SQLERRM);
  END;

  --------Query for fetching hierarchy_id for External       ---------
  BEGIN

    SELECT CC.hierarchy_id
    INTO   ln_cc_rollup_grp
    FROM   fnd_flex_hierarchies_vl CC
    WHERE  CC.hierarchy_code = p_cc_rolup_grp_name
    AND    CC.flex_value_set_id = ln_cc_value_set_id;

  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Hierarchy IDs not found for External. '
                                    || SQLERRM);
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching Hierarchy IDs not found for External. '
                                    || SQLERRM);
  END;

  -- End changes for Defect 9274

  FOR lr_ledger_balances IN lcu_ledger_balances(ln_acct_value_set_id,ln_cc_value_set_id,ln_acc_rollup_grp,ln_cc_rollup_grp,p_coa_id)
  LOOP

    IF (lc_previous_company <> lr_ledger_balances.COMPANY) THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Company: ' || lc_previous_company ||'  Number of rows extracted: '||ln_com_count);
      ln_com_count := 0;
    END IF;
    ln_com_count := ln_com_count+1;
    lc_previous_company := lr_ledger_balances.COMPANY;

       -- Start changes for defect 11192
    IF(lr_ledger_balances.currency_code = 'CAD') THEN
       ln_sob_ytd_bal_cad := ln_sob_ytd_bal_cad + lr_ledger_balances.ytd_bal;         -- Added for Defect
    ELSIF(lr_ledger_balances.currency_code = 'USD')THEN
       ln_sob_ytd_bal_usd := ln_sob_ytd_bal_usd + lr_ledger_balances.ytd_bal;         -- Added for Defect
    ELSE
       ln_sob_ytd_bal_stat := ln_sob_ytd_bal_stat + lr_ledger_balances.ytd_bal;         -- Added for Defect
    END IF;
      -- End changes for defect 11192

    -- Start changes for defect 9274
    IF (SUBSTR(lr_ledger_balances.segment3,1,1) = '8') THEN
      lr_ledger_balances.acct_parent := lc_parent_acc;
    END IF;

    IF (lr_ledger_balances.acct_parent IS NULL) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Missing Parent account for the - Account: '|| lr_ledger_balances.segment3);
    END IF;

    IF (lr_ledger_balances.cc_parent IS NULL) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Missing Parent Cost Center for the - Cost Center: '|| lr_ledger_balances.segment2);
    END IF;
    -- End changes for defect 9274

    -------------------- Writing GL Balances into text file -------------------
    BEGIN

      UTL_FILE.PUT_LINE(lt_file, p_sob_name
                               || '|'   ||lr_ledger_balances.actual_flag
                               || '|'   ||lr_ledger_balances.period_name
                               || '|'   ||lr_ledger_balances.period_year
                               || '|'   ||lr_ledger_balances.currency_code
                               || '|'   ||lr_ledger_balances.COMPANY -- Company
                               || '|'   ||lr_ledger_balances.segment5 -- Intercompany
                               || '|'   ||lr_ledger_balances.acct_parent -- Parent Account
                               || '|'   ||lr_ledger_balances.segment3 -- Account
                               || '|'   ||lr_ledger_balances.acct_description -- Account Description
                               || '|'   ||lr_ledger_balances.cc_parent -- Parent Cost Center -- Defect 9274
                               || '|'   ||lr_ledger_balances.segment2 -- Cost Center
                               || '|'   ||lr_ledger_balances.segment4 -- Location
                               || '|'   ||lr_ledger_balances.segment6 -- LOB
                               || '|'   ||lr_ledger_balances.ytd_bal  -- NET YTD Balance
                               );

    EXCEPTION
    WHEN OTHERS THEN
      ln_error_flag := 1;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while writing into Text file'|| SQLERRM);
    END;
  END LOOP;

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Company: ' || lc_previous_company ||'  Number of rows extracted: '||ln_com_count);
  lc_previous_company := NULL;
  ln_com_count := 0;

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Set of Books: ' || p_sob_name || ' Period: ' || p_period_name ||' Currency: '||'CAD'|| ' Total Posted Amount: ' || ln_sob_ytd_bal_cad);     -- Added for Defect 11192
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Set of Books: ' || p_sob_name || ' Period: ' || p_period_name ||' Currency: '||'USD'|| ' Total Posted Amount: ' || ln_sob_ytd_bal_usd);     -- Added for Defect 11192
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Set of Books: ' || p_sob_name || ' Period: ' || p_period_name ||' Currency: '||'STAT'|| ' Total Posted Amount: ' || ln_sob_ytd_bal_stat);   -- Added for Defect 11192

  UTL_FILE.fclose(lt_file);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'');
  IF ln_error_flag = 0 THEN
     FND_FILE.PUT_LINE(FND_FILE.LOG,'The GL Balances have been written into the file successfully.');
  END IF;

/*  FOR lr_ledger_bal_rec_num IN lcu_ledger_bal_rec_num
  LOOP
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Company: ' || lr_ledger_bal_rec_num.segment1
                                     || '   Number of Rows extracted: ' || lr_ledger_bal_rec_num.cnt);
  END LOOP;

  --------- Call the Common file copy Program to archive the file into $XXFIN_ARCHIVE/outbound -------

  lc_source_file_name  := lc_source_file_path  || '/' || p_file_name;
  lc_dest_file_name    := lc_archive_file_path || '/' || SUBSTR(p_file_name,1,LENGTH(p_file_name) - 4)
                                               || TO_CHAR(SYSDATE, 'DD-MON-YYYYHHMMSS') || '.txt';

  FND_FILE.PUT_LINE(FND_FILE.LOG,'');
  FND_FILE.PUT_LINE(FND_FILE.LOG,'The Created File Name    : ' || lc_source_file_name);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'The Archived File Path   : ' || lc_dest_file_name);

  ln_req_id := FND_REQUEST.SUBMIT_REQUEST ('xxfin'
                                           ,'XXCOMFILCOPY'
                                           ,''
                                           ,''
                                           ,FALSE
                                           ,lc_source_file_name
                                           ,lc_dest_file_name
                                           ,NULL
                                           ,NULL
                                          );

  FND_FILE.PUT_LINE(FND_FILE.LOG,'');
  FND_FILE.PUT_LINE(FND_FILE.LOG,'The File was Archived into ' ||  lc_archive_file_path
                                    || '. Request id : ' || ln_req_id);
  COMMIT;

  ----------- Wait for the Common file copy Program to Complete -----------

  lb_req_status := FND_CONCURRENT.WAIT_FOR_REQUEST(request_id  => ln_req_id
                                                   ,interval    => '2'
                                                   ,max_wait    => ''
                                                   ,phase       => lc_phase
                                                   ,status      => lc_status
                                                   ,dev_phase   => lc_devphase
                                                   ,dev_status  => lc_devstatus
                                                   ,message     => lc_message
                                                  );

  FND_FILE.PUT_LINE(FND_FILE.LOG,'*************************************************************');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'*************************************************************');
EXCEPTION
WHEN OTHERS THEN
  IF UTL_FILE.is_open(lt_file) THEN
    UTL_FILE.fclose(lt_file);
  END IF;
  FND_MESSAGE.SET_NAME('XXFIN','XX_GL_0006_BAL_EXT_OTHERS');
  FND_MESSAGE.SET_TOKEN('COL','GL Balance');
  lc_error_msg := FND_MESSAGE.GET;
  XX_COM_ERROR_LOG_PUB.LOG_ERROR (p_program_type             => 'CONCURRENT PROGRAM'
                                  ,p_program_name            => 'OD: GL Daily Balance Extract Program'
                                  ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                  ,p_module_name             => 'GL'
                                  ,p_error_location          => 'Oracle Error '||SQLERRM
                                  ,p_error_message_count     => ln_msg_cnt + 1
                                  ,p_error_message_code      => 'E'
                                  ,p_error_message           => lc_error_msg
                                  ,p_error_message_severity  => 'Major'
                                  ,p_notify_flag             => 'N'
                                  ,p_object_type             => 'GL Balance Extract'
                                 );

END WRITE_TO_FILE;*/

/*****************R 1.2 CR 585 QC 2841 Fix****************Starts****************/
-- +====================================================================+
-- | Name : WRITE_TO_FILE_TR                                            |
-- | Description : extracts ledger balances for a given period and sob, |
-- |               only fetches for the USD translated account values   |
-- |               from gl balances and writes into a separate .txt     |
-- |               files for the current and prior fiscal years         |
-- |               and archives the file                                |
-- | Parameters :  p_set_of_books_id,p_currency_code,                   |
-- |               p_chart_of_accounts_id,p_period_name_from,           |
-- |               p_period_name_to,p_file_name                         |
-- +====================================================================+

PROCEDURE write_to_file_tr (p_set_of_books_id           IN NUMBER
                            ,p_currency_code            IN VARCHAR2
                            ,p_coa_id                   IN NUMBER
                            ,p_period_name_from         IN DATE
                            ,p_period_name_to           IN DATE
                            ,p_file_name                IN VARCHAR2
                            ,p_sob_name                 IN VARCHAR2
                            )
IS
-------------Variables Declaration-------------
  ln_cur_count                NUMBER  :=0;
  lt_tr_file                  UTL_FILE.FILE_TYPE;
  lc_tr_file_path             VARCHAR2(500) := 'XXFIN_DAILY';
  lc_tr_source_file_path      VARCHAR2(500);
  lc_tr_dest_file_path        VARCHAR2(500) := '$XXFIN_DATA/ftp/out/hyperion';
  lc_tr_archive_file_path     VARCHAR2(500) := '$XXFIN_ARCHIVE/outbound';
  lc_tr_source_file_name      VARCHAR2(1000);
  lc_tr_dest_file_name        VARCHAR2(1000);
  ln_buffer                   BINARY_INTEGER := 32767;
  lc_tranvalue                VARCHAR2(100);
  ln_tr_error_flag            NUMBER := 0;
  lc_tr_scenario              VARCHAR2(1000);
  lc_tr_layer                 VARCHAR2(1000);
  ln_tr_req_id                NUMBER(10);
  lb_tr_req_status            BOOLEAN;
  lc_tr_flag                  VARCHAR2(10) := 'N';
  lc_error_msg                VARCHAR2(1000);
  lc_phase                    VARCHAR2(1000);
  lc_status                   VARCHAR2(50);
  ln_msg_cnt                  NUMBER := 0;
  lc_devstatus                VARCHAR2(50);
  lc_devphase                 VARCHAR2(50);
  lc_message                  VARCHAR2(50);
  lc_company                  gl_code_combinations.segment1%TYPE := NULL;
  ln_company_cnt              NUMBER  :=0;
  ln_sob_ytd_bal_usd          NUMBER  :=0;
  --------   Cursor for extracting GL Balances   ---------

   CURSOR lcu_gl_translated_amount
   IS
     SELECT  GLB.period_name
            ,TO_CHAR(TO_DATE(GLB.period_name,'MON-RR'),'MON') period
            ,GLB.period_year
            ,GCC.segment1 company
            ,GCC.segment2
            ,GCC.segment3
            ,GCC.segment4
            ,GCC.segment6
            ,currency_code
            ,SUM((GLB.begin_balance_dr-GLB.begin_balance_cr + GLB.period_net_dr-GLB.period_net_cr)) ytd_trans_bal
     FROM   gl_balances  GLB
            ,gl_code_combinations GCC
     --WHERE  GLB.set_of_books_id       = p_set_of_books_id                                 --commented by kiran V(2.5) as per R12 Retrofit Change
     WHERE  GLB.ledger_id       = p_set_of_books_id                                         --added by kiran V(2.5) as per R12 Retrofit Change
     AND    TO_DATE(GLB.period_name,'MON-RR') BETWEEN p_period_name_from AND p_period_name_to
     AND    GLB.translated_flag IN ('Y','N')
     AND    GLB.currency_code = 'USD'
     AND    GLB.actual_flag = 'A'
     AND    GCC.chart_of_accounts_id = p_coa_id
     AND    GCC.template_id IS NULL
     AND    GCC.code_combination_id   = GLB.code_combination_id
     AND    GCC.segment3 IN (SELECT XFTV.target_value5
                           FROM xx_fin_translatedefinition  XFTD
                                ,xx_fin_translatevalues      XFTV
                           WHERE XFTV.translate_id = XFTD.translate_id
                           AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
                           AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
                           AND XFTV.source_value5 = 'Translated_account'
                           AND XFTD.translation_name = 'XX_GL_1360_BALANCE_EXT'
                           AND XFTV.enabled_flag = 'Y'
                           AND XFTD.enabled_flag = 'Y')
     GROUP BY
             GLB.period_name
            ,TO_CHAR(TO_DATE(GLB.period_name,'MON-RR'),'MON')
            ,GLB.period_year
            ,GCC.segment1
            ,GCC.segment2
            ,GCC.segment3
            ,GCC.segment4
            ,GCC.segment6
            ,currency_code
    ORDER BY TO_DATE(GLB.period_name,'MON-RR'),GCC.segment1,GCC.segment3;

BEGIN

  FND_FILE.PUT_LINE(FND_FILE.LOG,'*************************************************************');
  FND_FILE.PUT_LINE(FND_FILE.LOG,'SOB Name             : ' || p_sob_name);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Currency             : ' || p_currency_code);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Period Name From     : ' || p_period_name_from);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Period Name To       : ' || p_period_name_to);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Chart of Account ID  : ' || p_coa_id);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'-------------------------------------------------------------');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'*************************************************************');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'SOB Name             : ' || p_sob_name);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Currency             : ' || p_currency_code);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Period Name From     : ' || p_period_name_from);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Period Name To       : ' || p_period_name_to);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Chart of Account ID  : ' || p_coa_id);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------------------------');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The GL Balance Extract File Name for Translated Account balances     : ' || p_file_name);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------------------------');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Created File Path for Translated Account balances              : ' || lc_tr_file_path);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Destination File Path for Translated Account balances          : ' || lc_tr_dest_file_path);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'*************************************************************');


  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Translated - Start Time ' || TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
  FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

   --------Getting source file path for the translated acct balances --------
   BEGIN
     SELECT directory_path
     INTO   lc_tr_source_file_path
     FROM   dba_directories
     WHERE  directory_name = lc_tr_file_path;
   EXCEPTION
     WHEN OTHERS THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching the File Path XXFIN_DAILY in translated account balances '
                                       || SQLERRM);
   END;

   --------Get the Currency from translation --------

   BEGIN
     SELECT XFTV.target_value1
     INTO  lc_tranvalue
     FROM xx_fin_translatedefinition  XFTD
         ,xx_fin_translatevalues      XFTV
     WHERE XFTV.translate_id = XFTD.translate_id
     AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
     AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
     AND XFTV.source_value1 = 'Currency_TR'
     AND XFTD.translation_name = 'XX_GL_1360_BALANCE_EXT'
     AND XFTV.enabled_flag = 'Y'
     AND XFTD.enabled_flag = 'Y';
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'No values found in translation for the Currency tran value in translated account balances        ');
     WHEN OTHERS THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching values for the tran value in translated account balances       '
                                       || SQLERRM);
   END;

   -------- Fetching value for Scenario from translation   --------
   BEGIN
     SELECT UPPER(XFTV.target_value1)
     INTO lc_tr_scenario
     FROM xx_fin_translatedefinition  XFTD
         ,xx_fin_translatevalues      XFTV
     WHERE XFTV.translate_id = XFTD.translate_id
     AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
     AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
     AND XFTV.source_value1 = 'Scenario'
     AND XFTD.translation_name = 'XX_GL_1360_BALANCE_EXT'
     AND XFTV.enabled_flag = 'Y'
     AND XFTD.enabled_flag = 'Y';
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'No values found for Scenario from translation in translated account balances  ');
     WHEN OTHERS THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching values from translation for Scenario in translated account balances   '
                                       || SQLERRM);
   END;
   --------Fetching value for Layer from translation  --------
   BEGIN
     SELECT XFTV.target_value1
     INTO lc_tr_layer
     FROM xx_fin_translatedefinition  XFTD
         ,xx_fin_translatevalues      XFTV
     WHERE XFTV.translate_id = XFTD.translate_id
     AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
     AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
     AND XFTV.source_value1 = 'Layer'
     AND XFTD.translation_name = 'XX_GL_1360_BALANCE_EXT'
     AND XFTV.enabled_flag = 'Y'
     AND XFTD.enabled_flag = 'Y';
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
     FND_FILE.PUT_LINE(FND_FILE.LOG,'No values found for Layer from translation in translated account balances');
   WHEN OTHERS THEN
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching values from translation for Layer in translated account balances  '
                                    || SQLERRM);
   END;

    --------  Opening the cursor for translated account balances    --------
  FOR lr_gl_translated_amount IN lcu_gl_translated_amount
  LOOP
     ln_cur_count := ln_cur_count +1;

  --------Opening the file for Translated Account Balances  --------
   IF ln_cur_count = 1
   THEN
     BEGIN
       lt_tr_file := UTL_FILE.fopen(lc_tr_file_path, p_file_name,'w',ln_buffer);
       lc_tr_flag := 'Y';
     EXCEPTION
       WHEN OTHERS THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while Opening the file.in translated account balances '|| SQLERRM);
     END;
   END IF;

  -------- Calculating the ytd balance for Translated Account Balances  --------
     IF(lr_gl_translated_amount.currency_code = 'USD') THEN
       ln_sob_ytd_bal_usd := ln_sob_ytd_bal_usd + lr_gl_translated_amount.ytd_trans_bal;
     END IF;

   -------- Writing into the file for for Translated Account Balances  --------
     BEGIN
       UTL_FILE.PUT_LINE(lt_tr_file, lc_tr_scenario                             -- Scenario
                                 || '|'   ||lr_gl_translated_amount.period
                                 || '|'   ||lr_gl_translated_amount.period_year
                                 || '|'   ||lr_gl_translated_amount.company       -- Company
                                 || '|'   ||lr_gl_translated_amount.segment3      -- Account
                                 || '|'   ||lr_gl_translated_amount.segment2      -- Cost Center
                                 || '|'   ||lr_gl_translated_amount.segment6      -- LOB
                                 || '|'   ||lr_gl_translated_amount.segment4      -- Location
                                 || '|'   ||p_currency_code || '.' || lc_tranvalue -- Currency
                                 || '|'   ||lc_tr_layer                           -- Layer
                                 || '|'   ||lr_gl_translated_amount.ytd_trans_bal -- NET YTD Translated Balance
                                 );
     EXCEPTION
       WHEN OTHERS THEN
         ln_tr_error_flag := 1;
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while writing into Text file in translated account balances'|| SQLERRM);
     END;

  END LOOP;  -- Closing of Translated Account Balances Cursor

  --------  Total posted amount for translated balances  --------

   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------------------------');
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Set of Books :  ' || p_sob_name || ' Period From:  ' || p_period_name_from ||
                                     ' Period To:  ' || p_period_name_to ||' Currency:  '||'USD'||
                                     ' Total Posted Amount  : ' || ln_sob_ytd_bal_usd);

 --------Closing the file for Translated Account Balances  --------

   IF UTL_FILE.is_open(lt_tr_file)
   THEN
      UTL_FILE.fclose(lt_tr_file);
   END IF;

   IF ln_tr_error_flag = 0 THEN
     FND_FILE.PUT_LINE(FND_FILE.LOG,'The GL Balances have been written into the file successfully in translated account balances ');
     FND_FILE.PUT_LINE(FND_FILE.LOG,'*************************************************************');
   END IF;
 --------  Generating the source and destination file name for Translated Account Balances   --------
     lc_tr_source_file_name      := lc_tr_source_file_path  || '/' || p_file_name;
     lc_tr_dest_file_name        := lc_tr_archive_file_path || '/' || SUBSTR(p_file_name,1,LENGTH(p_file_name) - 4)
                                               || TO_CHAR(SYSDATE, 'DD-MON-YYYYHHMMSS') || '.txt';

     FND_FILE.PUT_LINE(FND_FILE.LOG,'The Created File Name in translated account balances   : ' || lc_tr_source_file_name);
     FND_FILE.PUT_LINE(FND_FILE.LOG,'The Archived File Path in translated account balances  : ' || lc_tr_dest_file_name);
 --------  Submitting common file copy program for Translated Account Balances   --------
   IF (lc_tr_flag ='Y')
   THEN
     ln_tr_req_id := FND_REQUEST.SUBMIT_REQUEST  ('xxfin'
                                                  ,'XXCOMFILCOPY'
                                                  ,''
                                                  ,''
                                                  ,FALSE
                                                  ,lc_tr_source_file_name
                                                  ,lc_tr_dest_file_name
                                                  ,NULL
                                                  ,NULL
                                                   );
     FND_FILE.PUT_LINE(FND_FILE.LOG,'The Translated Account Balances File was Archived into ' ||  lc_tr_archive_file_path
                                                || ' **** Request id ****: ' || ln_tr_req_id);
     COMMIT;
   --------- Wait for the Common file copy Program to Complete for Translated Account Balances   --------
     lb_tr_req_status := FND_CONCURRENT.WAIT_FOR_REQUEST(request_id  => ln_tr_req_id
                                                        ,interval    => '2'
                                                        ,max_wait    => ''
                                                        ,phase       => lc_phase
                                                        ,status      => lc_status
                                                        ,dev_phase   => lc_devphase
                                                        ,dev_status  => lc_devstatus
                                                        ,message     => lc_message
                                                        );
     FND_FILE.PUT_LINE(FND_FILE.LOG,'*************************************************************');
   END IF;

END write_to_file_tr;

-- +===================================================================+
-- | Name : TRANSLATED_ACC_BALANCES                                    |
-- | Description : extracts the translated account balances and sob    |
-- |               values for the passed period name and call          |
-- |               the write to file tr procedure                      |
-- |               to write into a .txt file for the prior             |
-- |               and current fiscal year                             |
-- |                                                                   |
-- | Parameters :  p_period_name                                       |
-- +===================================================================+
PROCEDURE translated_acc_balances (p_period_name  IN  VARCHAR2)
IS
   --------- Variables declaration   ---------
        lc_tr_file_name               VARCHAR2(1000);
        lc_period_year                VARCHAR2(10);
        ld_tr_date                    DATE;
        lc_tranvalue                  VARCHAR2(1000);
        ld_tr_period_name_from        DATE;
        ld_tr_period_name_to          DATE;
        ln_prior_cnt                  NUMBER;
        lc_time                       VARCHAR2(100);
   --------- Cursor for fetching the Set of Books ---------
  CURSOR lcu_sob
  IS
     --commented by kiran V(2.5) as per R12 Retrofit Change
     /*SELECT GSB.set_of_books_id
            ,GSB.short_name
            ,GSB.name
            ,GSB.currency_code
            ,GSB.chart_of_accounts_id
     FROM   gl_sets_of_books GSB*/
     --added by kiran V(2.5) as per R12 Retrofit Change
     SELECT GL.ledger_id
           ,GL.short_name
           ,GL.name
           ,GL.currency_code
           ,GL.chart_of_accounts_id
     FROM   gl_ledgers gl
     --WHERE  GSB.attribute1 = 'Y'
     WHERE GL.attribute1 = 'Y'
     --ended by kiran V(2.5) as per R12 Retrofit Change
     AND    short_name IN (SELECT XFTV.target_value1
                           FROM xx_fin_translatedefinition  XFTD
                               ,xx_fin_translatevalues      XFTV
                           WHERE XFTV.translate_id = XFTD.translate_id
                           AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
                           AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
                           --AND XFTV.source_value1 = 'Canada SOB'
					AND XFTV.source_value1 in ('Canada SOB','UK SOB')		-- GBP Tranvalue fix
                           AND XFTD.translation_name = 'XX_GL_1360_BALANCE_EXT'
                           AND XFTV.enabled_flag = 'Y'
                           AND XFTD.enabled_flag = 'Y');
 BEGIN
  ---------Open the Set of books id Cursor   ---------
   FOR lr_sob IN lcu_sob
   LOOP

     ---------  Get the From Period, To Period and Year   ---------

                ld_tr_period_name_from := TRUNC(TO_DATE(p_period_name,'MON-RR'),'RR');
                ld_tr_period_name_to   := TO_DATE(p_period_name,'MON-RR');
                lc_period_year         := TO_CHAR(TO_DATE(p_period_name,'MON-YY'),'RR');

   ---------   Get the Tran value from translation   ---------
     BEGIN
       SELECT XFTV.target_value1
       INTO   lc_tranvalue
       FROM xx_fin_translatedefinition  XFTD
           ,xx_fin_translatevalues      XFTV
       WHERE XFTV.translate_id = XFTD.translate_id
       AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
       AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
       AND XFTV.source_value1 = 'TranFile_Name'
       AND XFTD.translation_name = 'XX_GL_1360_BALANCE_EXT'
       AND XFTV.enabled_flag = 'Y'
       AND XFTD.enabled_flag = 'Y';
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'No values found in translation for the Currency tran value in translated account balances        ');
       WHEN OTHERS THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching values for the tran value in translated account balances       '
                                                        || SQLERRM);
     END;
   ---------Generate the current fiscal year file name   ---------
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Activity has been found for Current FY for Translated Account Balances');
      lc_tr_file_name := lr_sob.currency_code || lc_tranvalue || 'FY'||lc_period_year ||'.txt';

   ---------Calling write to file tr procedure for current fiscal year   ---------
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Calling Write to File to generate file for Current FY for Translated Account Balances');
      --write_to_file_tr (lr_sob.set_of_books_id                --commented by kiran V(2.5) as per R12 Retrofit Change
      write_to_file_tr (lr_sob.ledger_id                        --added by kiran V(2.5) as per R12 Retrofit Change
                       ,lr_sob.currency_code
                       ,lr_sob.chart_of_accounts_id
                       ,ld_tr_period_name_from
                       ,ld_tr_period_name_to
                       ,lc_tr_file_name
                       ,lr_sob.short_name
                       );
   --------- Reinitializing Period From, Period To , File name and Year Variables   ---------
      ld_tr_period_name_from := NULL;
      ld_tr_period_name_to   := NULL;
      lc_tr_file_name        := NULL;
      lc_period_year         := NULL;

   --------- Checking for Prior year for the passed period name   ---------
   --------- Get the last extract date Value from custom daily bal extract table   ---------
     BEGIN
       SELECT MAX(last_extract_date)
       INTO   ld_tr_date
       FROM   xx_gl_daily_bal_extract
       --WHERE  set_of_books_id = lr_sob.set_of_books_id;    --commented by kiran V(2.5) as per R12 Retrofit Change
       WHERE  set_of_books_id = lr_sob.ledger_id;            --added by kiran V(2.5) as per R12 Retrofit Change
     EXCEPTION
       WHEN OTHERS THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching values for the last extract date       '
                                      || SQLERRM);
     END;
   ---------Getting values for the prior periods and year    ---------

        ld_tr_period_name_from := TRUNC(ADD_MONTHS(TO_DATE(p_period_name,'MON-RR'), -12),'RR');
        ld_tr_period_name_to := ADD_MONTHS(TRUNC(ADD_MONTHS(TO_DATE(p_period_name,'MON-RR'), -12),'RR'),11);
        lc_period_year := TO_CHAR(TRUNC(ADD_MONTHS(TO_DATE(p_period_name,'MON-RR'), -12),'RR'),'RR');

   --------- Counting values to get the prior period    ---------
     BEGIN
       SELECT COUNT(*)
       INTO ln_prior_cnt
       FROM gl_translation_statuses
       WHERE last_run_date > ld_tr_date
       --AND set_of_books_id = lr_sob.set_of_books_id         --commented by kiran V(2.5) as per R12 Retrofit Change
       AND ledger_id = lr_sob.ledger_id                       --added by kiran V(2.5) as per R12 Retrofit Change
       AND TO_DATE(period_name,'MON-RR') BETWEEN ld_tr_period_name_from AND ld_tr_period_name_to
       AND status = 'C';
     EXCEPTION
       WHEN OTHERS THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while counting values for the translated statuses        '
                                       || SQLERRM);
     END;

     IF (ln_prior_cnt>0) THEN
    ---------  Generating file name for the Prior year    ---------

        FND_FILE.PUT_LINE(FND_FILE.LOG,'');
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Activity has been found for prior FY for translated account balances');
        lc_tr_file_name := lr_sob.currency_code || lc_tranvalue || 'FY'||lc_period_year ||'.txt';

    ---------  Calling write to file tr procedure for Prior year    ---------
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Calling write to file to generate file for Prior FY for translated account balances');
        --write_to_file_tr (lr_sob.set_of_books_id                --commented by kiran V(2.5) as per R12 Retrofit Change
        write_to_file_tr (lr_sob.ledger_id                        --added by kiran V(2.5) as per R12 Retrofit Change
                         ,lr_sob.currency_code
                         ,lr_sob.chart_of_accounts_id
                         ,ld_tr_period_name_from
                         ,ld_tr_period_name_to
                         ,lc_tr_file_name
                         ,lr_sob.short_name
                          );
     ELSE
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'No Prior FY Activity found for translated account balances');
     END IF;
   END LOOP;
 END translated_acc_balances;

-- +===================================================================+
-- | Name : GL_BAL_EXTRACT_FTP                                         |
-- | Description : Procedure to ftp the file                           |
-- |                                                                   |
-- | Parameters :  p_source_file                                       |
-- |               Added for defect 21004			       |
-- +===================================================================+
PROCEDURE GL_BAL_EXTRACT_FTP(p_source_file IN VARCHAR2)
IS

ln_req_id	NUMBER;

BEGIN

  --- Call the OD: Common Put Program to FTP  ( Changed OD_FMR_GL_BAL) -- Defect 21004

  FND_FILE.PUT_LINE(FND_FILE.LOG, '');
  FND_FILE.PUT_LINE(FND_FILE.LOG, '*************************************************************');
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'FTPing zip file to SFTP server');
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Source file name :'||p_source_file);
  FND_FILE.PUT_LINE(FND_FILE.LOG, '');

  ln_req_id := FND_REQUEST.SUBMIT_REQUEST( application => 'XXFIN'
                                          ,program     => 'XXCOMFTP'
                                          ,description => 'GL Balances File FTP PUT'
                                          ,sub_request => FALSE
                                          ,argument1   => 'OD_FMR_GL_BAL'       -- Row from OD_FTP_PROCESSES translation
                                          ,argument2   => p_source_file         -- Source file name
                                          ,argument3   => NULL                  -- Dest file name
                                          ,argument4   => 'Y'                   -- Delete source file
                                         );
  COMMIT;
  IF ln_req_id = 0 THEN
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Error : Unable to submit FTP program to send GL Balances file');
  ELSE
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Submitted FTP file to SFTP server. Request id : '|| ln_req_id);
  END IF;
EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in GL_BAL_EXTRACT_FTP :'||SQLERRM);
END GL_BAL_EXTRACT_FTP;




/*****************R 1.2 CR 585 QC 2841 Fix****************Ends****************/

-- +===================================================================+
-- | Name : GL_BAL_DAILY_EXTRACT                                       |
-- | Description : extracts the ledger balances and COA segments on a  |
-- |               daily basis from Oracle General Ledger and copies   |
-- |               on to a data file                                   |
-- | Parameters :  p_sob_name, p_year, p_period_name                   |
-- +===================================================================+
PROCEDURE GL_BAL_DAILY_EXTRACT(p_sob_name       IN  VARCHAR2
                               ,p_year           IN  NUMBER
                               ,p_period_name    IN  VARCHAR2
                               ,p_acc_rolup_grp_name   IN VARCHAR2
                               ,p_cc_rolup_grp_name    IN VARCHAR2
                              )
IS
  lb_req_status        BOOLEAN;
  ln_period_status     NUMBER;
  ld_timestamp         DATE;
  lc_period_num        VARCHAR2(2);
  lc_file_name         VARCHAR2(100);
  lc_file_path         VARCHAR2(500) := 'XXFIN_DAILY';
  lc_source_file_path  VARCHAR2(500);
  lc_dest_file_path    VARCHAR2(500) := '$XXFIN_DATA/ftp/out/hyperion';
  lc_dest_file_name    VARCHAR2(1000);
  lc_ftp_file_name     VARCHAR2(1000);
  lc_phase             VARCHAR2(50);
  lc_status            VARCHAR2(50);
  lc_devphase          VARCHAR2(50);
  lc_devstatus         VARCHAR2(50);
  lc_message           VARCHAR2(50);
  lc_error_msg         VARCHAR2(4000);
  ld_zip_date          VARCHAR2(50);  --- added for defect 12031
  ln_req_id            NUMBER(10);
  ln_msg_cnt           NUMBER := 0;
  ln_appl_id           fnd_application.application_id%TYPE;
  lc_period_name       gl_balances.period_name%TYPE;
  lc_pre_period_name   gl_balances.period_name%TYPE; -- Defect 8761
  lc_period_status     VARCHAR2(1) := 'Y'; -- Defect 8761

/*****************R 1.2 CR 745 QC 2841 Fix****************Starts****************/
 --Local variables declaration

  lc_excluded_file_name      VARCHAR2(5000);
  lc_non_excluded_file_name  VARCHAR2(5000);
  lc_country                 VARCHAR2(100);
  lc_scenario                VARCHAR2(100);
  lc_time                    VARCHAR2(100);

/*****************R 1.2 CR 745 QC 2841 Fix****************Ends****************/

  lc_excluded_file_name_mtd      VARCHAR2(5000);  -- Added for the CR 634 Defect # 6428 - Release 1.4
  lc_non_excluded_file_name_mtd  VARCHAR2(5000);  -- Added for the CR 634 Defect # 6428 - Release 1.4

  --------------Cursor Query for fetching the Set of Books ------------
  CURSOR lcu_set_of_books
  IS
  --commented by kiran V(2.5) as per R12 Retrofit Change
  /*SELECT GSB.set_of_books_id
         ,GSB.short_name
         ,GSB.name
         ,GSB.currency_code
         ,GSB.chart_of_accounts_id
  FROM   gl_sets_of_books GSB
  WHERE  GSB.attribute1 = 'Y'
  AND    GSB.short_name = DECODE(p_sob_name,'ALL',GSB.short_name,p_sob_name);*/
  --added by kiran V(2.5) as per R12 Retrofit Change
  SELECT GL.ledger_id
        ,GL.short_name
        ,GL.name
        ,GL.currency_code
        ,GL.chart_of_accounts_id
  FROM   gl_ledgers GL
  WHERE  GL.attribute1 = 'Y'
  AND    GL.short_name = DECODE(p_sob_name,'ALL',GL.short_name,p_sob_name);
  --ended by kiran V(2.5) as per R12 Retrofit Change
BEGIN
  SELECT SYSDATE
  INTO   ld_timestamp
  FROM   dual;
  BEGIN
    SELECT application_id
    INTO   ln_appl_id
    FROM   fnd_application
    WHERE  application_short_name = 'SQLGL';
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching the application ID. '
                                   || SQLERRM);
  END;
  --------Fetch the directory path for the directory XXFIN_DAILY-----------
  BEGIN
    SELECT directory_path
    INTO   lc_source_file_path
    FROM   dba_directories
    WHERE  directory_name = lc_file_path;
  EXCEPTION
  WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching the File Path XXFIN_OUTBOUND. '
                                 || SQLERRM);
  END;

/*****************R 1.2 CR 745 QC 2841 Fix****************Starts****************/
  -------- Fetch the value from translation for scenario --------
  BEGIN
    SELECT XFTV.target_value1
    INTO lc_scenario
    FROM xx_fin_translatedefinition  XFTD
        ,xx_fin_translatevalues      XFTV
    WHERE XFTV.translate_id = XFTD.translate_id
    AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
    AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
    AND XFTV.source_value1 = 'Scenario'
    AND XFTD.translation_name = 'XX_GL_1360_BALANCE_EXT'
    AND XFTV.enabled_flag = 'Y'
    AND XFTD.enabled_flag = 'Y';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'No value found for scenario from translation       ');

    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching values from translation for SCENARIO    '
                                     || SQLERRM);
  END;
/*****************R 1.2 CR 745 QC 2841 Fix****************Ends****************/

  FOR lr_set_of_books IN lcu_set_of_books
  LOOP
    lc_period_name := NULL; -- Defect 8761
    lc_period_status   := 'Y'; -- Defect 8761
    FOR ln_count IN 1..3
    LOOP
      IF ln_count = 1 THEN
        lc_period_name := p_period_name;
        BEGIN
          -----------Query for fetching period_num for the current period---------
          SELECT LPAD(GPS.period_num, 2,0)
          INTO   lc_period_num
          FROM   gl_period_statuses GPS
          --WHERE  GPS.set_of_books_id = lr_set_of_books.set_of_books_id                 --commented by kiran V(2.5) as per R12 Retrofit Change
          WHERE  GPS.ledger_id = lr_set_of_books.ledger_id                               --added by kiran V(2.5) as per R12 Retrofit Change
          AND    GPS.application_id = ln_appl_id
          AND    GPS.period_name = p_period_name;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while finding the Period Num. '|| SQLERRM);
        END;
        ln_period_status := 1;
      ELSE
        get_period_name(lc_period_name
                        ,lc_period_num
                        ,ln_count
                        --,lr_set_of_books.set_of_books_id                               --commented by kiran V(2.5) as per R12 Retrofit Change
                        ,lr_set_of_books.ledger_id                                       --added by kiran V(2.5) as per R12 Retrofit Change
                        ,p_period_name);
        --ln_period_status := get_period_status(lr_set_of_books.set_of_books_id          --commented by kiran V(2.5) as per R12 Retrofit Change
        ln_period_status := get_period_status(lr_set_of_books.ledger_id                  --added by kiran V(2.5) as per R12 Retrofit Change
                                              ,lr_set_of_books.currency_code
                                              ,lc_period_name);
      END IF;

      IF ln_period_status = 1 THEN

/*****************R 1.2 CR 745 QC 2841 Fix****************Starts****************/

       SELECT DECODE(lr_set_of_books.currency_code,'USD','NA','CAD','CAD','GBP','GBP')
       INTO lc_country
       FROM dual;
	   
	   --v3.0/NAIT-199391 start
	   IF LR_SET_OF_BOOKS.SHORT_NAME='R_US_USD_P'
	   THEN 
	   lc_country := lc_country||'RE';
	   END IF;
	   --v3.0/NAIT-199391 end

     /*lc_file_name := lc_period_num || '~ORA_' || lr_set_of_books.currency_code
                          || '_' || lc_period_num || '~Actual~'
                          || TO_CHAR(TO_DATE(lc_period_name,'MON-YY'),'Mon-YYYY') || '~RR' || '.txt';*/   -- Removed for CR 745 Defect 2841 R 1.2

  -------- File name generation for Excluded and Non Excluded Company  --------

     lc_excluded_file_name := lc_period_num || '~ORA_' || lr_set_of_books.short_name
                              || '_' || lc_period_num  || '~Actual~'
                              || TO_CHAR(TO_DATE(lc_period_name,'MON-YY'),'Mon-YYYY') || '~RR' || '.txt';

     lc_non_excluded_file_name := lc_scenario||TO_CHAR(TO_DATE(lc_period_name,'MON-YY'),'Mon')||lc_country||'FY'
                                             ||TO_CHAR(TO_DATE(lc_period_name,'MON-YY'),'RR') || '.txt';

/*****************R 1.2 CR 745 QC 2841 Fix****************Ends****************/

/*****************R 1.4 CR 634 QC DefectID#6428 Fix****************Start****************/

  -------- File name generation for Excluded and Non Excluded Company for MTD balances --------

     lc_excluded_file_name_mtd := lc_period_num || '~ORA_' || lr_set_of_books.short_name
                              || '_' || lc_period_num  || '~Actual~'
                              || TO_CHAR(TO_DATE(lc_period_name,'MON-YY'),'Mon-YYYY') || '~RR' || '_MTD' || '.txt';

     lc_non_excluded_file_name_mtd := lc_scenario||TO_CHAR(TO_DATE(lc_period_name,'MON-YY'),'Mon')||lc_country||'FY'
                                             ||TO_CHAR(TO_DATE(lc_period_name,'MON-YY'),'RR') || '_MTD' || '.txt';

/*****************R 1.4 CR 634 QC DefectID#6428 Fix****************Ends****************/


-- Start for changes Defect-8761
        IF lc_period_status = 'N' THEN
          lc_pre_period_name := lc_period_name;
          lc_file_name := lc_period_num || '~ORA_' || lr_set_of_books.short_name
                            || '_' || lc_period_num || '~Actual~'
                            || TO_CHAR(TO_DATE(lc_pre_period_name,'MON-YY'),'Mon-YYYY') || '~RR' || '.txt';

    FND_FILE.PUT_LINE(FND_FILE.LOG,'**** STARTS -  Translation Values ****   ' || TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));

          write_to_file(--lc_file_name                       -- Commented for CR 745 Defect 2841 R 1.2
                        lc_excluded_file_name                -- Added for the CR 745 Defect 2841 R 1.2
                        ,lc_non_excluded_file_name           -- Added for the CR 745 Defect 2841 R 1.2
                        ,lc_excluded_file_name_mtd           -- Added for the CR 634 Defect # 6428 - Release 1.4
                        ,lc_non_excluded_file_name_mtd       -- Added for the CR 634 Defect # 6428 - Release 1.4
                        ,lc_source_file_path
                        --,lr_set_of_books.set_of_books_id                    --commented by kiran V(2.5) as per R12 Retrofit Change
                        ,lr_set_of_books.ledger_id                            --added by kiran V(2.5) as per R12 Retrofit Change
                        ,lr_set_of_books.short_name
                        ,lr_set_of_books.chart_of_accounts_id
                        ,lr_set_of_books.currency_code
                        ,lc_pre_period_name
                        ,ln_appl_id
                        ,p_acc_rolup_grp_name
                        ,p_cc_rolup_grp_name
                        );
        END IF;
-- End for changes Defect-8761

/*****************R 1.2 CR 745 QC 2841 Fix****************Starts****************/

          FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling Write to file by passing Excluded File name                       :'|| lc_excluded_file_name);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling Write to file by passing Non Excluded File name                   :'|| lc_non_excluded_file_name);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'');
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling Write to file by passing Excluded File name for MTD Balances      :'|| lc_excluded_file_name_mtd);     -- Added for the CR 634 Defect # 6428 - Release 1.4
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling Write to file by passing Non Excluded File name for MTD Balances  :'|| lc_non_excluded_file_name_mtd); -- Added for the CR 634 Defect # 6428 - Release 1.4


/*****************R 1.2 CR 745 QC 2841 Fix****************Ends****************/

          write_to_file( --lc_file_name                    -- Commented for CR 745 Defect 2841 R 1.2
                       lc_excluded_file_name               -- Added for CR 745 Defect 2841 R 1.2
                       ,lc_non_excluded_file_name          -- Added for CR 745 Defect 2841 R 1.2
                       ,lc_excluded_file_name_mtd          -- Added for the CR 634 Defect # 6428 - Release 1.4
                       ,lc_non_excluded_file_name_mtd      -- Added for the CR 634 Defect # 6428 - Release 1.4
                       ,lc_source_file_path
                       --,lr_set_of_books.set_of_books_id                    --commented by kiran V(2.5) as per R12 Retrofit Change
                       ,lr_set_of_books.ledger_id                            --added by kiran V(2.5) as per R12 Retrofit Change
                       ,lr_set_of_books.short_name
                       ,lr_set_of_books.chart_of_accounts_id
                       ,lr_set_of_books.currency_code
                       ,lc_period_name
                       ,ln_appl_id
                       ,p_acc_rolup_grp_name
                       ,p_cc_rolup_grp_name
                       );
        lc_pre_period_name := lc_period_name; -- Defect 8761
        lc_period_status   := 'Y'; -- Defect 8761

        ---------Merge statement to Insert a record in xx_gl_daily_bal_extract if it----------
        ---------does not exist. If the record exists, last_extract_date will be updated--------
        BEGIN
          MERGE INTO xx_gl_daily_bal_extract GDB
          --USING (SELECT lr_set_of_books.set_of_books_id set_of_books_id, lc_period_name period_name     --commented by kiran V(2.5) as per R12 Retrofit Change
          USING (SELECT lr_set_of_books.ledger_id set_of_books_id, lc_period_name period_name
                 FROM   dual) D
          ON    (GDB.set_of_books_id = D.set_of_books_id
          AND    GDB.period_name = D.period_name)
          WHEN MATCHED THEN
            UPDATE SET GDB.last_extract_date = ld_timestamp
          WHEN NOT MATCHED THEN
            INSERT (GDB.set_of_books_id, GDB.period_name, GDB.last_extract_date)
            VALUES (D.set_of_books_id, D.period_name, ld_timestamp);
        EXCEPTION
          WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while Merging data into xx_gl_daily_bal_extract. '
                                           || SQLERRM);
        END;
      ELSE
        lc_pre_period_name := lc_period_name; -- Defect 8761
        lc_period_status   := 'N'; -- Defect 8761
      END IF;
    END LOOP;
  END LOOP;

  /*****************R 1.2 CR 585 QC 2841 Fix****************Starts****************/
------------- Calling of Translated Account Balances Procedure --------------

        translated_acc_balances(p_period_name);

/*****************R 1.2 CR 585 QC 2841 Fix****************Ends****************/

---added for defect 12031
   SELECT to_char(sysdate,'MMDDYYYY_HH24MISS')
     INTO   ld_zip_date
     FROM   DUAL;
  lc_dest_file_name := lc_dest_file_path || '/GL_Hyperion_Daily_'||ld_zip_date;

  lc_ftp_file_name :='GL_Hyperion_Daily_'||ld_zip_date||'.zip';

  --------------- Call the ZIP Directory Program to ZIP the Daily Folder-------------
  --------------- and put the Daily.zip file into $XXFIN_DATA/ftp/out/hyperion-------------
  ln_req_id := FND_REQUEST.SUBMIT_REQUEST('xxfin'
                                          ,'XXODDIRZIP' -- Defect 8930
                                          ,''
                                          ,''
                                          ,FALSE
                                          ,lc_source_file_path
                                          ,lc_dest_file_name
                                          );
  COMMIT;
  lb_req_status := FND_CONCURRENT.WAIT_FOR_REQUEST(request_id  => ln_req_id
                                                   ,interval    => '2'
                                                   ,max_wait    => ''
                                                   ,phase       => lc_phase
                                                   ,status      => lc_status
                                                   ,dev_phase   => lc_devphase
                                                   ,dev_status  => lc_devstatus
                                                   ,message     => lc_message
                                                  );
   -- Defect 21004 Added call to FTP;
   GL_BAL_EXTRACT_FTP(lc_ftp_file_name);
EXCEPTION
WHEN OTHERS THEN
     FND_FILE.PUT_LINE(FND_FILE.LOG,' Error in GL BAL DAILY EXTRACT ...'||SQLERRM);

END GL_BAL_DAILY_EXTRACT;


-- +====================================================================+
-- | Name : GL_BAL_MONTHLY_EXTRACT                                      |
-- | Description : extracts the ledger balances and COA segments on a   |
-- |               monthly basis from Oracle General Ledger and copies  |
-- |               on to a data file                                    |
-- | Parameters :  x_err_buff, x_ret_code, p_sob_name, p_year,          |
-- |               p_period_name                                        |
-- | Returns :     Return Code, Error buff                              |
-- +====================================================================+
PROCEDURE GL_BAL_MONTHLY_EXTRACT(x_err_buff      OUT NOCOPY VARCHAR2
                                 ,x_ret_code     OUT NUMBER
                                 ,p_sob_name     IN  VARCHAR2
                                 ,p_year         IN  NUMBER
                                 ,p_period_name  IN  VARCHAR2
                                 ,p_acc_rolup_grp_name   IN VARCHAR2
                                 ,p_cc_rolup_grp_name    IN VARCHAR2
                                )
IS
  lc_period_num            VARCHAR2(2);
  lc_file_name             VARCHAR2(100);
  ln_old_trans             NUMBER := 0;
  ln_trans_balances        NUMBER := 0;
  ln_cc_value_set_id       NUMBER; -- Defect 9274
  ln_acct_value_set_id     NUMBER;
  lb_req_status1           BOOLEAN;
  lb_req_status2           BOOLEAN;
  lc_file_path             VARCHAR2(500) := 'XXFIN_OUTBOUND';
  lc_source_file_path      VARCHAR2(500);
  lc_dest_file_path        VARCHAR2(500) := '$XXFIN_DATA/ftp/out/hyperion';
  lc_archive_file_path     VARCHAR2(500) := '$XXFIN_ARCHIVE/outbound';
  lc_source_file_name      VARCHAR2(1000);
  lc_dest_file_name        VARCHAR2(1000);
  lc_phase                 VARCHAR2(50);
  lc_status                VARCHAR2(50);
  lc_devphase              VARCHAR2(50);
  lc_devstatus             VARCHAR2(50);
  lc_message               VARCHAR2(50);
  lc_error_msg             VARCHAR2(4000);
  ln_req_id1               NUMBER(10);
  ln_req_id2               NUMBER(10);
  ln_req_id3               NUMBER(10);
  ln_msg_cnt               NUMBER := 0;
  lt_file                  UTL_FILE.FILE_TYPE;
  ln_buffer                BINARY_INTEGER := 32767;
  ln_appl_id           fnd_application.application_id%TYPE;
  ln_sob_ytd_trans_bal_cad  NUMBER ;                                     -- Added for Defect 11192
  ln_sob_ytd_trans_bal_usd  NUMBER ;                                     -- Added for Defect 11192
  ln_sob_ytd_trans_bal_stat NUMBER ;                                     -- Added for Defect 11192
  ln_com_count              NUMBER :=0;
  lc_previous_company  gl_code_combinations.segment1%TYPE := NULL;
  ln_acc_rollup_grp        NUMBER; -- Defect 9274
  ln_cc_rollup_grp         NUMBER; -- Defect 9274
  ln_error_flag            NUMBER := 0;
  lc_parent_acc            CONSTANT fnd_flex_value_norm_hierarchy.parent_flex_value%TYPE := 'P8000000'; -- Defect 9274
  --------------Cursor Query for fetching the Set of Books ------------
  CURSOR lcu_set_of_books
  IS
  --commented by kiran V(2.5) as per R12 Retrofit Change
  /*SELECT GSB.set_of_books_id
         ,GSB.short_name
         ,GSB.name
         ,GSB.currency_code
         ,GSB.chart_of_accounts_id
  FROM   gl_sets_of_books GSB
  WHERE  GSB.attribute1 = 'Y'
  AND    GSB.short_name = DECODE(p_sob_name,'ALL',GSB.short_name,p_sob_name);*/
  --added by kiran V(2.5) as per R12 Retrofit Change
  SELECT GL.ledger_id
        ,GL.short_name
        ,GL.name
        ,GL.currency_code
        ,GL.chart_of_accounts_id
  FROM   gl_ledgers GL
  WHERE  GL.attribute1 = 'Y'
  AND    GL.short_name = DECODE(p_sob_name,'ALL',GL.short_name,p_sob_name);
  --ended by kiran V(2.5) as per R12 Retrofit Change
  --------Cursor Query for extracting GL Balances---------
  CURSOR lcu_gl_balances(p_set_of_books_id   IN NUMBER
                        ,p_currency_code     IN VARCHAR2
                        ,p_acct_value_set_id IN NUMBER
                        ,p_cc_value_set_id   IN NUMBER
                        ,p_acc_rollup_grp    IN NUMBER -- Defect 9274
                        ,p_cc_rollup_grp     IN NUMBER -- Defect 9274
                        ,p_coa_id            IN NUMBER)
  IS
-- Start changes for defect - 9274
--Query to fetch the records where the parents exist for both account and cost center
--Added Hint for Defect 7186
  SELECT   /*+ leading(GLB) no_merge(AC) no_merge(AC1) no_merge(CC1) */
          GLB.period_name
         ,GLB.actual_flag
         ,GLB.period_year
         ,GCC.segment1 COMPANY
         ,GCC.segment2
         ,GCC.segment3
         ,AC_PAR.parent_flex_value acct_parent
         ,CC_PAR.parent_flex_value cc_parent -- Defect 9274
         ,AC.description acct_description
         ,GCC.segment4
         ,GCC.segment5
         ,GCC.segment6
         ,GCC.segment7
         ,GLB.currency_code
         ,GLB.translated_flag
         ,(GLB.begin_balance_dr-GLB.begin_balance_cr + GLB.period_net_dr-GLB.period_net_cr) ytd_trans_bal
  FROM   gl_balances  GLB
         ,gl_code_combinations GCC
         ,fnd_flex_values_vl AC
         ,fnd_flex_values_vl AC1
         ,fnd_flex_value_norm_hierarchy AC_PAR
         ,fnd_flex_values_vl CC1
         ,fnd_flex_value_norm_hierarchy CC_PAR
  --WHERE  GLB.set_of_books_id = p_set_of_books_id                     --commented by kiran V(2.5) as per R12 Retrofit Change
  WHERE  GLB.ledger_id = p_set_of_books_id                             --added by kiran V(2.5) as per R12 Retrofit Change
  AND    GLB.period_name = p_period_name
AND    ((GLB.translated_flag IN ('Y','N') AND GLB.currency_code = 'USD')
           OR
          ((GLB.translated_flag IS NULL AND GLB.currency_code = 'STAT')
            OR
           (GLB.translated_flag IS NULL AND GLB.currency_code = 'USD' AND p_currency_code = 'USD')
          )
         )
  AND    GLB.actual_flag = 'A'
  AND    GCC.chart_of_accounts_id = p_coa_id
  AND    GCC.template_id IS NULL
  AND    GCC.code_combination_id   = GLB.code_combination_id
  AND    CC_PAR.parent_flex_value = CC1.flex_value
  AND    CC1.flex_value_set_id = p_cc_value_set_id
  AND    CC1.structured_hierarchy_level = p_cc_rollup_grp
  AND    CC_PAR.flex_value_set_id = p_cc_value_set_id
  AND    GCC.segment2 BETWEEN CC_PAR.child_flex_value_low AND CC_PAR.child_flex_value_high
  AND    AC_PAR.parent_flex_value = AC1.flex_value
  AND    AC1.flex_value_set_id = p_acct_value_set_id
  AND    AC1.structured_hierarchy_level = p_acc_rollup_grp
  AND    AC.flex_value_set_id = p_acct_value_set_id
  AND    AC_PAR.flex_value_set_id = p_acct_value_set_id
  AND    AC.flex_value BETWEEN AC_PAR.child_flex_value_low AND AC_PAR.child_flex_value_high
  AND    AC.flex_value = gcc.segment3
  AND    AC1.enabled_flag = 'Y'                                -- Uncommented for Defect 11050
  AND    AC.enabled_flag = 'Y'                                 -- Uncommented for Defect 11050
  AND    CC1.enabled_flag = 'Y'
  UNION ALL
  --Query to fetch values where account parent does not exist and cost center parent exist
  --Added Hint for Defect 7186
  SELECT /*+ leading(GLB) no_merge(AC) no_merge(CC1)*/
         GLB.period_name
         ,GLB.actual_flag
         ,GLB.period_year
         ,GCC.segment1 COMPANY
         ,GCC.segment2
         ,GCC.segment3
         ,'' acct_parent
         ,CC_PAR.parent_flex_value cc_parent
         ,AC.description acct_description
         ,GCC.segment4
         ,GCC.segment5
         ,GCC.segment6
         ,GCC.segment7
         ,GLB.currency_code
         ,GLB.translated_flag
         ,(GLB.begin_balance_dr-GLB.begin_balance_cr + GLB.period_net_dr-GLB.period_net_cr) ytd_trans_bal
  FROM   gl_balances  GLB
         ,gl_code_combinations GCC
         ,fnd_flex_values_vl AC
         ,fnd_flex_values_vl CC1
         ,fnd_flex_value_norm_hierarchy CC_PAR
  --WHERE  GLB.set_of_books_id = p_set_of_books_id                     --commented by kiran V(2.5) as per R12 Retrofit Change
  WHERE  GLB.ledger_id = p_set_of_books_id                             --added by kiran V(2.5) as per R12 Retrofit Change
  AND    GLB.period_name = p_period_name
  AND    GCC.code_combination_id   = GLB.code_combination_id
  AND    ((GLB.translated_flag IN ('Y','N') AND GLB.currency_code = 'USD')
           OR
          ((GLB.translated_flag IS NULL AND GLB.currency_code = 'STAT')
            OR
           (GLB.translated_flag IS NULL AND GLB.currency_code = 'USD' AND p_currency_code = 'USD')
          )
         )
  AND    GLB.actual_flag = 'A'
  AND    GCC.template_id IS NULL
  AND    GCC.chart_of_accounts_id = p_coa_id
  AND    AC.flex_value_set_id = p_acct_value_set_id
  AND    AC.flex_value = GCC.segment3
  AND    AC.enabled_flag = 'Y'                                   -- Uncommented for Defect 11050
  AND NOT EXISTS( SELECT /*+ use_hash(AC1 AC_PAR)*/ 1
                  FROM fnd_flex_value_norm_hierarchy AC_PAR , fnd_flex_values AC1
                  WHERE AC_PAR.flex_value_set_id = p_acct_value_set_id
                  AND GCC.segment3 BETWEEN AC_PAR.child_flex_value_low AND AC_PAR.child_flex_value_high
                  AND AC1.flex_value = AC_PAR.parent_flex_value
                  AND AC1. flex_value_set_id = p_acct_value_set_id
                  AND AC1.structured_hierarchy_level = p_acc_rollup_grp
                  AND AC1.enabled_flag = 'Y'                     -- Uncommented for Defect 11050
                )
  AND    CC_PAR.parent_flex_value = CC1.flex_value
  AND    CC1.flex_value_set_id = p_cc_value_set_id
  AND    CC1.structured_hierarchy_level = p_cc_rollup_grp
  AND    CC_PAR.flex_value_set_id = p_cc_value_set_id
  AND    GCC.segment2 BETWEEN CC_PAR.child_flex_value_low AND CC_PAR.child_flex_value_high
  UNION ALL
  --Query to fetch records where both cost center parent and account parent do not exist
  --Added Hint for Defect 7186
  SELECT /*+ leading(GLB) no_merge(AC) */
         GLB.period_name
         ,GLB.actual_flag
         ,GLB.period_year
         ,GCC.segment1 COMPANY
         ,GCC.segment2
         ,GCC.segment3
         ,'' acct_parent
         ,'' cc_parent
         ,AC.description acct_description
         ,GCC.segment4
         ,GCC.segment5
         ,GCC.segment6
         ,GCC.segment7
         ,GLB.currency_code
         ,GLB.translated_flag
         ,(GLB.begin_balance_dr-GLB.begin_balance_cr + GLB.period_net_dr-GLB.period_net_cr) ytd_trans_bal
  FROM   gl_balances  GLB
         ,gl_code_combinations GCC
         ,fnd_flex_values_vl AC
  --WHERE  GLB.set_of_books_id = p_set_of_books_id                     --commented by kiran V(2.5) as per R12 Retrofit Change
  WHERE  GLB.ledger_id = p_set_of_books_id                             --added by kiran V(2.5) as per R12 Retrofit Change
  AND    GLB.period_name = p_period_name
  AND    GCC.code_combination_id   = GLB.code_combination_id
  AND    ((GLB.translated_flag IN ('Y','N') AND GLB.currency_code = 'USD')
           OR
          ((GLB.translated_flag IS NULL AND GLB.currency_code = 'STAT')
            OR
           (GLB.translated_flag IS NULL AND GLB.currency_code = 'USD' AND p_currency_code = 'USD')
          )
         )
  AND    GLB.actual_flag = 'A'
  AND    GCC.template_id IS NULL
  AND    GCC.chart_of_accounts_id = p_coa_id
  AND    AC.flex_value_set_id = p_acct_value_set_id
  AND    AC.flex_value = GCC.segment3
  AND    AC.enabled_flag = 'Y'                              -- Uncommented for Defect 11050
  AND NOT EXISTS( SELECT /*+ use_hash(AC1 AC_PAR)*/ 1
                  FROM fnd_flex_value_norm_hierarchy AC_PAR , fnd_flex_values AC1
                  WHERE AC_PAR.flex_value_set_id = p_acct_value_set_id
                  AND GCC.segment3 BETWEEN AC_PAR.child_flex_value_low AND AC_PAR.child_flex_value_high
                  AND AC1.flex_value = AC_PAR.parent_flex_value
                  AND AC1. flex_value_set_id = p_acct_value_set_id
                  AND AC1.structured_hierarchy_level = p_acc_rollup_grp
                  AND AC1.enabled_flag = 'Y'                -- Uncommented for Defect 11050
                )
  AND NOT EXISTS( SELECT /*+ use_hash(CC1 CC_PAR)*/ 1
                  FROM fnd_flex_value_norm_hierarchy CC_PAR, fnd_flex_values CC1
                  WHERE CC_PAR.flex_value_set_id = p_cc_value_set_id
                  AND GCC.segment2 BETWEEN CC_PAR.child_flex_value_low AND CC_PAR.child_flex_value_high
                  AND CC1.flex_value = CC_PAR.parent_flex_value
                  AND CC1. flex_value_set_id = p_cc_value_set_id
                  AND CC1.structured_hierarchy_level = p_cc_rollup_grp
                  AND CC1.enabled_flag = 'Y'
                )
  UNION ALL
 --Query to fetch the records where parent account exists but parent cost center does not exist
 --Added Hint for Defect 7186
  SELECT  /*+ leading(GLB) no_merge(AC) no_merge(AC1)*/ GLB.period_name
         ,GLB.actual_flag
         ,GLB.period_year
         ,GCC.segment1 COMPANY
         ,GCC.segment2
         ,GCC.segment3
         ,AC_PAR.parent_flex_value acct_parent
         ,'' cc_parent
         ,AC.description acct_description
         ,GCC.segment4
         ,GCC.segment5
         ,GCC.segment6
         ,GCC.segment7
         ,GLB.currency_code
         ,GLB.translated_flag
         ,(GLB.begin_balance_dr-GLB.begin_balance_cr + GLB.period_net_dr-GLB.period_net_cr) ytd_trans_bal
  FROM   gl_balances  GLB
         ,gl_code_combinations GCC
         ,fnd_flex_values_vl AC
         ,fnd_flex_values_vl AC1
         ,fnd_flex_value_norm_hierarchy AC_PAR
  --WHERE  GLB.set_of_books_id = p_set_of_books_id                     --commented by kiran V(2.5) as per R12 Retrofit Change
  WHERE  GLB.ledger_id = p_set_of_books_id                             --added by kiran V(2.5) as per R12 Retrofit Change
  AND    GLB.period_name = p_period_name
  AND    GCC.code_combination_id   = GLB.code_combination_id
  AND    ((GLB.translated_flag IN ('Y','N') AND GLB.currency_code = 'USD')
           OR
          ((GLB.translated_flag IS NULL AND GLB.currency_code = 'STAT')
            OR
           (GLB.translated_flag IS NULL AND GLB.currency_code = 'USD' AND p_currency_code = 'USD')
          )
         )
  AND    GLB.actual_flag = 'A'
  AND    GCC.template_id IS NULL
  AND    GCC.chart_of_accounts_id = p_coa_id
  AND    AC_PAR.parent_flex_value = AC1.flex_value
  AND    AC1.flex_value_set_id = p_acct_value_set_id
  AND    AC1.structured_hierarchy_level = p_acc_rollup_grp
  AND    AC.flex_value_set_id = p_acct_value_set_id
  AND    AC_PAR.flex_value_set_id = p_acct_value_set_id
  AND    AC.flex_value BETWEEN AC_PAR.child_flex_value_low AND AC_PAR.child_flex_value_high
  AND    AC.flex_value = gcc.segment3
  AND    AC.enabled_flag = 'Y'                               -- Uncommented for Defect 11050
  AND    AC1.enabled_flag = 'Y'                              -- Uncommented for Defect 11050
  AND NOT EXISTS( SELECT  /*+ use_hash(CC1 CC_PAR)*/  1
                  FROM fnd_flex_value_norm_hierarchy CC_PAR, fnd_flex_values CC1
                  WHERE CC_PAR.flex_value_set_id = p_cc_value_set_id
                  AND   GCC.segment2 BETWEEN CC_PAR.child_flex_value_low AND CC_PAR.child_flex_value_high
                  AND   CC1.flex_value = CC_PAR.parent_flex_value
                  AND   CC1. flex_value_set_id = p_cc_value_set_id
                  AND   CC1.structured_hierarchy_level = p_cc_rollup_grp
                  AND   CC1.enabled_flag = 'Y'
                )
  ORDER BY COMPANY;
-- End changes for defect - 9274
/*  SELECT GLB.period_name
         ,GLB.actual_flag
         ,GLB.period_year
         ,GLB.translated_flag
         ,GLB.currency_code
         ,(GLB.begin_balance_dr-GLB.begin_balance_cr + GLB.period_net_dr-GLB.period_net_cr) ytd_trans_bal
         ,GCC.segment1 COMPANY
         ,GCC.segment2
         ,GCC.segment3
         ,GCC.segment4
         ,GCC.segment5
         ,GCC.segment6
         ,GCC.segment7
         ,AC_PAR.parent_flex_value acct_parent
         ,CC_PAR.parent_flex_value cc_parent -- Defect 9274
         ,AC.description acct_description
  FROM   (fnd_flex_value_norm_hierarchy AC_PAR RIGHT OUTER JOIN fnd_flex_values_vl AC
          ON  AC_PAR.flex_value_set_id = p_acct_value_set_id
              AND SYSDATE BETWEEN (NVL(AC_PAR.start_date_active,SYSDATE)) AND (NVL(AC_PAR.start_date_active,SYSDATE)) -- Defect 9274
              AND  AC.flex_value BETWEEN AC_PAR.child_flex_value_low AND AC_PAR.child_flex_value_high
              AND AC.enabled_flag = 'Y' -- Defect 9274
              AND SYSDATE BETWEEN (NVL(AC.start_date_active,SYSDATE)) AND (NVL(AC.start_date_active,SYSDATE))) -- Defect 9274
          LEFT OUTER JOIN fnd_flex_values_vl AC1 -- Defect 9274
            ON  AC_PAR.flex_value_set_id = p_acct_value_set_id -- Defect 9274
            AND AC_PAR.flex_value_set_id IS NULL -- Defect 9274
            AND AC_PAR.parent_flex_value = AC1.flex_value -- Defect 9274
            AND AC1.structured_hierarchy_level = p_acc_rollup_grp -- Defect 9274
         ,(fnd_flex_value_norm_hierarchy CC_PAR RIGHT OUTER JOIN fnd_flex_values_vl CC -- Defect 9274
          ON  CC_PAR.flex_value_set_id = p_cc_value_set_id
              AND SYSDATE BETWEEN (NVL(CC_PAR.start_date_active,SYSDATE)) AND (NVL(CC_PAR.start_date_active,SYSDATE)) -- Defect 9274
              AND  CC.flex_value BETWEEN CC_PAR.child_flex_value_low AND CC_PAR.child_flex_value_high
              AND CC.enabled_flag = 'Y' -- Defect 9274
              AND SYSDATE BETWEEN (NVL(CC.start_date_active,SYSDATE)) AND (NVL(CC.start_date_active,SYSDATE))) -- Defect 9274
          LEFT OUTER JOIN fnd_flex_values_vl CC1 -- Defect 9274
             ON CC_PAR.flex_value_set_id = p_cc_value_set_id -- Defect 9274
             AND CC_PAR.flex_value_set_id IS NULL -- Defect 9274
             AND CC_PAR.parent_flex_value = CC1.flex_value -- Defect 9274
             AND CC1.structured_hierarchy_level = p_cc_rollup_grp -- Defect 9274
         ,gl_code_combinations GCC
         ,gl_balances  GLB
  WHERE  GLB.set_of_books_id = p_set_of_books_id
  AND    GLB.period_name = p_period_name
  AND    ((GLB.translated_flag IN ('Y','N') AND GLB.currency_code = 'USD')
           OR
          ((GLB.translated_flag IS NULL AND GLB.currency_code = 'STAT')
            OR
           (GLB.translated_flag IS NULL AND GLB.currency_code = 'USD' AND p_currency_code = 'USD')
          )
         )
  AND    GLB.actual_flag = 'A'
  AND    GCC.chart_of_accounts_id = p_coa_id
  AND    GCC.template_id IS NULL
  AND    AC.flex_value_set_id = p_acct_value_set_id
  AND    CC.flex_value_set_id = p_cc_value_set_id -- Defect 9274
  AND    GCC.code_combination_id   = GLB.code_combination_id
  AND    AC.flex_value = GCC.segment3
  AND    CC.flex_value = GCC.segment2 -- Defect 9274
  ORDER BY COMPANY;*/
--  AND    CC.flex_value_set_id = p_cc_value_set_id
--  AND    CC.flex_value = gcc.segment2
--  AND    CC_PAR.flex_value_set_id = p_cc_value_set_id
--  AND    CC.flex_value BETWEEN CC_PAR.child_flex_value_low AND CC_PAR.child_flex_value_high
--  AND    GLB.currency_code = 'USD'
--  AND    AC_PAR.flex_value_set_id = p_acct_value_set_id
--  AND    AC.flex_value BETWEEN AC_PAR.child_flex_value_low AND AC_PAR.child_flex_value_high
/*  UNION ALL
  SELECT GLB.period_name
         ,GLB.actual_flag
         ,GLB.period_year
         ,GCC.segment1 COMPANY
         ,GCC.segment2
         ,GCC.segment3
         ,'-' acct_parent
--         ,CC_PAR.parent_flex_value cc_parent
         ,AC.description acct_description
         ,GCC.segment4
         ,GCC.segment5
         ,GCC.segment6
         ,GCC.segment7
         ,GLB.currency_code
         ,(GLB.begin_balance_dr-GLB.begin_balance_cr + GLB.period_net_dr-GLB.period_net_cr) ytd_trans_bal
  FROM   gl_balances  GLB
         ,gl_code_combinations GCC
         ,fnd_flex_values_vl AC
--         ,fnd_flex_value_norm_hierarchy AC_PAR
--         ,fnd_flex_values_vl CC
--         ,fnd_flex_value_norm_hierarchy CC_PAR
  WHERE  GLB.set_of_books_id = p_set_of_books_id
  AND    GLB.period_name = p_period_name
  AND    GCC.code_combination_id   = GLB.code_combination_id
--  AND    CC.flex_value_set_id = p_cc_value_set_id
--  AND    CC.flex_value = gcc.segment2
--  AND    CC_PAR.flex_value_set_id = p_cc_value_set_id
--  AND    CC.flex_value BETWEEN CC_PAR.child_flex_value_low AND CC_PAR.child_flex_value_high
--  AND    GLB.currency_code = 'USD'
  AND    ((GLB.translated_flag IN ('Y','N') AND GLB.currency_code = 'USD')
           OR
          (GLB.translated_flag IS NULL AND GLB.currency_code = 'STAT')
         )
  AND    GLB.actual_flag = 'A'
  AND    GCC.template_id IS NULL
  AND    AC.flex_value_set_id = p_acct_value_set_id
  AND    AC.flex_value = gcc.segment3
  AND    GCC.chart_of_accounts_id = p_coa_id
  AND NOT EXISTS( SELECT 1
                  FROM fnd_flex_value_norm_hierarchy AC_PAR
                  WHERE AC_PAR.flex_value_set_id = p_acct_value_set_id
                  AND AC.flex_value BETWEEN AC_PAR.child_flex_value_low AND AC_PAR.child_flex_value_high
                )
  ORDER BY COMPANY;*/
/*  UNION ALL
  SELECT GB.period_name
         ,GB.actual_flag
         ,GB.period_year
         ,GCC.segment1
         ,GCC.segment2
         ,GCC.segment3
         ,AC_PAR.parent_flex_value acct_parent
--         ,CC_PAR.parent_flex_value cc_parent
         ,AC.description acct_description
         ,GCC.segment4
         ,GCC.segment5
         ,GCC.segment6
         ,GCC.segment7
         ,GB.currency_code
         ,(GB.begin_balance_dr-GB.begin_balance_cr + GB.period_net_dr-GB.period_net_cr) ytd_trans_bal
  FROM   gl_balances  GB
         ,gl_code_combinations GCC
         ,fnd_flex_values_vl AC
         ,fnd_flex_value_norm_hierarchy AC_PAR
--         ,fnd_flex_values_vl CC
--         ,fnd_flex_value_norm_hierarchy CC_PAR
  WHERE  GB.set_of_books_id = p_set_of_books_id
  AND    GB.period_name = p_period_name
  AND    GCC.code_combination_id   = GB.code_combination_id
  AND    AC.flex_value_set_id = p_acct_value_set_id
  AND    AC.flex_value = gcc.segment3
  AND    AC_PAR.flex_value_set_id = p_acct_value_set_id
  AND    AC.flex_value BETWEEN AC_PAR.child_flex_value_low AND AC_PAR.child_flex_value_high
--  AND    CC.flex_value_set_id = p_cc_value_set_id
--  AND    CC.flex_value = gcc.segment2
--  AND    CC_PAR.flex_value_set_id = p_cc_value_set_id
--  AND    CC.flex_value BETWEEN CC_PAR.child_flex_value_low AND CC_PAR.child_flex_value_high
  AND    GB.currency_code = 'STAT'
  AND    GB.actual_flag = 'A'
  AND    GCC.template_id IS NULL;*/
  --------Cursor Query for counting the number of rows extracted per Company---------
/*  CURSOR lcu_bal_rec_num(p_set_of_books_id IN NUMBER)
  IS
  SELECT segment1
         ,COUNT(1) cnt
  FROM   (SELECT GLB.period_name
                 ,GLB.actual_flag
                 ,GLB.period_year
                 ,GCC.segment1
                 ,GCC.segment2
                 ,GCC.segment3
                 ,GCC.segment4
                 ,GCC.segment5
                 ,GCC.segment6
                 ,GCC.segment7
                 ,GLB.currency_code
          FROM   gl_balances  GLB
                 ,gl_code_combinations GCC
          WHERE  GLB.set_of_books_id = p_set_of_books_id
          AND    GLB.period_name = p_period_name
          AND    GCC.code_combination_id   = GLB.code_combination_id
          AND    GLB.currency_code = 'USD'
          AND    GLB.translated_flag ='Y'
          AND    GLB.actual_flag = 'A'
          AND    GCC.template_id IS NULL
          UNION ALL
          SELECT GB.period_name
                 ,GB.actual_flag
                 ,GB.period_year
                 ,GCC.segment1
                 ,GCC.segment2
                 ,GCC.segment3
                 ,GCC.segment4
                 ,GCC.segment5
                 ,GCC.segment6
                 ,GCC.segment7
                 ,GB.currency_code
          FROM   gl_balances  GB
                 ,gl_code_combinations GCC
          WHERE  GB.set_of_books_id = p_set_of_books_id
          AND    GB.period_name = p_period_name
          AND    GCC.code_combination_id   = GB.code_combination_id
          AND    GB.currency_code = 'STAT'
          AND    GB.actual_flag = 'A'
          AND    GCC.template_id IS NULL)
  GROUP BY segment1;*/
BEGIN
  BEGIN
    SELECT application_id
    INTO   ln_appl_id
    FROM   fnd_application
    WHERE  application_short_name = 'SQLGL';
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching the application ID. '
                                    || SQLERRM);
  END;
  BEGIN
    SELECT directory_path
    INTO   lc_source_file_path
    FROM   dba_directories
    WHERE  directory_name = lc_file_path;
  EXCEPTION
  WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching the File Path XXFIN_OUTBOUND. '
                                    || SQLERRM);
  END;
  x_ret_code := 0;
  FOR lr_set_of_books IN lcu_set_of_books
  LOOP
    lc_previous_company := NULL;
    ln_com_count := 0;
    ln_sob_ytd_trans_bal_cad := 0;                        --Added for Defect 11192
    ln_sob_ytd_trans_bal_usd := 0;                        --Added for Defect 11192
    ln_sob_ytd_trans_bal_stat := 0;                       --Added for Defect 11192
    FND_FILE.PUT_LINE(FND_FILE.LOG,'*************************************************************');
    FND_FILE.PUT_LINE(FND_FILE.LOG,'SOB Name     : ' || lr_set_of_books.short_name);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Currency     : ' || lr_set_of_books.currency_code);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Period Name  : ' || p_period_name);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'-------------------------------------------------------------');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'*************************************************************');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'SOB Name     : ' || lr_set_of_books.short_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Currency     : ' || lr_set_of_books.currency_code);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Period Name  : ' || p_period_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------------------------');
/*  IF lr_set_of_books.currency_code <> 'USD' THEN
    ----------Query for checking if Out of Date Translations exist exist in the extraction run------
    BEGIN
      SELECT COUNT(DECODE(GLB.translated_flag,'N',1))
            ,COUNT(DECODE(GLB.translated_flag,'Y',1))
      INTO   ln_old_trans
            ,ln_trans_balances
      FROM   gl_balances  GLB
             ,gl_code_combinations GCC
      WHERE  GLB.set_of_books_id = lr_set_of_books.set_of_books_id
      AND    GLB.period_name = p_period_name
      AND    GCC.code_combination_id   = GLB.code_combination_id
      AND    GLB.currency_code = 'USD'
      AND    GLB.actual_flag = 'A'
      AND    GCC.template_id IS NULL;
    EXCEPTION
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception occurred while fetching the count of translated balances. '|| SQLERRM);
    END;
    IF ln_old_trans > 0 THEN
      x_ret_code := 1;
      x_err_buff := 'Out of date Translations exist in the extraction run';
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Out of date Translations exist in the extraction run');
    END IF;
    IF ln_trans_balances = 0 THEN
      x_ret_code := 1;
      x_err_buff := 'Null translated balances exist in the extraction run';
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Null translated balances exist in the extraction run.');
    END IF;
   END IF;*/
    -----------Query for fetching period_num for the current period---------
    BEGIN
      SELECT LPAD(GP.period_num, 2,0)
      INTO   lc_period_num
      FROM   gl_period_statuses GP
      WHERE  period_name = p_period_name
      --AND    GP.set_of_books_id = lr_set_of_books.set_of_books_id           --commented by kiran V(2.5) as per R12 Retrofit Change
      AND    GP.ledger_id = lr_set_of_books.ledger_id                         --added by kiran V(2.5) as per R12 Retrofit Change
      AND    GP.application_id = ln_appl_id;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Exception raised while trying to find period number.');
    END;
    lc_file_name := 'GL_Hyperion_' || lc_period_num || '~ORA_' || lr_set_of_books.short_name
                                  || '_' || lc_period_num || '~Actual~'
                                  || TO_CHAR(TO_DATE(p_period_name,'MON-YY'),'Mon-YYYY') || '~RR' || '.txt';
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The GL Balance Extract File Name : ' || lc_file_name);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'The Created File Path               : ' || lc_file_path);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'The Destination File Path           : ' || lc_dest_file_path);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'*************************************************************');
    BEGIN
      lt_file := UTL_FILE.fopen(lc_file_path, lc_file_name,'w',ln_buffer);
    EXCEPTION
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while Opening the file. '|| SQLERRM);
    END;
    --------Query for fetching flex_value_set_ids for Accounts and Cost Centers---------
    BEGIN
    SELECT distinct FFV_CC.flex_value_set_id
           ,FFV_AC.flex_value_set_id
    INTO   ln_cc_value_set_id -- Defect 9274
           ,ln_acct_value_set_id
    FROM   fnd_flex_value_sets FFV_CC -- Defect 9274
           ,fnd_id_flex_segments FSG_CC -- Defect 9274
           ,fnd_flex_value_sets FFV_AC
           ,fnd_id_flex_segments FSG_AC
    WHERE  FSG_CC.segment_name = 'Cost Center' -- Defect 9274
    AND    FSG_CC.flex_value_set_id = FFV_CC.flex_value_set_id -- Defect 9274
    AND    FSG_CC.id_flex_num = lr_set_of_books.chart_of_accounts_id -- Defect 9274
    AND    FSG_AC.segment_name = 'Account'
    AND    FSG_AC.flex_value_set_id = FFV_AC.flex_value_set_id
    AND    FSG_AC.id_flex_num = lr_set_of_books.chart_of_accounts_id;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Value Set IDs not found for Account and Cost Center. '
                                    || SQLERRM);
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching Value Set IDs for Account and Cost Center. '
                                    || SQLERRM);
  END;
  -- Start changes for  Defect 9274
  --------Query for fetching hierarchy_id for Report Line    ---------
  BEGIN
    SELECT ACC.hierarchy_id
    INTO   ln_acc_rollup_grp
    FROM   fnd_flex_hierarchies_vl ACC
    WHERE  ACC.hierarchy_code = p_acc_rolup_grp_name
    AND    ACC.flex_value_set_id = ln_acct_value_set_id;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Hierarchy IDs not found for Report Line. '
                                    || SQLERRM);
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching Hierarchy IDs not found for Report Line. '
                                    || SQLERRM);
  END;
  --------Query for fetching hierarchy_id for External       ---------
  BEGIN
    SELECT CC.hierarchy_id
    INTO   ln_cc_rollup_grp
    FROM   fnd_flex_hierarchies_vl CC
    WHERE  CC.hierarchy_code = p_cc_rolup_grp_name
    AND    CC.flex_value_set_id = ln_cc_value_set_id;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Hierarchy IDs not found for External. '
                                    || SQLERRM);
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching Hierarchy IDs not found for External. '
                                    || SQLERRM);
  END;
 -- End changes for Defect 9274
    --FOR lr_gl_balances IN lcu_gl_balances(lr_set_of_books.set_of_books_id,lr_set_of_books.currency_code,ln_acct_value_set_id,ln_cc_value_set_id,ln_acc_rollup_grp,ln_cc_rollup_grp,lr_set_of_books.chart_of_accounts_id)          --commented by kiran V(2.5) as per R12 Retrofit Change
    FOR lr_gl_balances IN lcu_gl_balances(lr_set_of_books.ledger_id,lr_set_of_books.currency_code,ln_acct_value_set_id,ln_cc_value_set_id,ln_acc_rollup_grp,ln_cc_rollup_grp,lr_set_of_books.chart_of_accounts_id)          --added by kiran V(2.5) as per R12 Retrofit Change
    LOOP
      IF (lc_previous_company <> lr_gl_balances.COMPANY) THEN
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Company: ' || lc_previous_company ||'  Number of rows extracted: '||ln_com_count);
        ln_com_count := 0;
      END IF;
         ln_com_count := ln_com_count+1;
         lc_previous_company := lr_gl_balances.COMPANY;
         -- Start changes for defect 11192
         IF(lr_gl_balances.currency_code = 'CAD') THEN
            ln_sob_ytd_trans_bal_cad := ln_sob_ytd_trans_bal_cad + lr_gl_balances.ytd_trans_bal;         -- Added for Defect
         ELSIF(lr_gl_balances.currency_code = 'USD')THEN
            ln_sob_ytd_trans_bal_usd := ln_sob_ytd_trans_bal_usd + lr_gl_balances.ytd_trans_bal;         -- Added for Defect
         ELSE
            ln_sob_ytd_trans_bal_stat := ln_sob_ytd_trans_bal_stat + lr_gl_balances.ytd_trans_bal;         -- Added for Defect
         END IF;
         -- End changes for defect 11192
      IF (lr_set_of_books.currency_code <> 'USD') THEN
         IF (lr_gl_balances.translated_flag = 'N') THEN
            ln_old_trans := ln_old_trans+1;
         END IF;
         IF (lr_gl_balances.translated_flag = 'Y') THEN
            ln_trans_balances := ln_trans_balances+1;
         END IF;
      END IF;
      -- Start changes for defect 9274
      IF (SUBSTR(lr_gl_balances.segment3,1,1) = '8') THEN
        lr_gl_balances.acct_parent := lc_parent_acc;
      END IF;
      IF (lr_gl_balances.acct_parent IS NULL) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Missing Parent account for the - Account: '|| lr_gl_balances.segment3);
      END IF;
      IF (lr_gl_balances.cc_parent IS NULL) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Missing Parent Cost Center for the - Cost Center: '|| lr_gl_balances.segment2);
      END IF;
      -- End changes for defect 9274
      ------------------ Writing GL Balances into text file -------------------
      BEGIN
        UTL_FILE.PUT_LINE(lt_file, lr_set_of_books.short_name
                                 || '|'   ||lr_gl_balances.actual_flag
                                 || '|'   ||lr_gl_balances.period_name
                                 || '|'   ||lr_gl_balances.period_year
                                 || '|'   ||lr_gl_balances.currency_code
                                 || '|'   ||lr_gl_balances.COMPANY -- Company
                                 || '|'   ||lr_gl_balances.segment5 -- Intercompany
                                 || '|'   ||lr_gl_balances.acct_parent -- Parent Account
                                 || '|'   ||lr_gl_balances.segment3 -- Account
                                 || '|'   ||lr_gl_balances.acct_description -- Account Description
                                 || '|'   ||lr_gl_balances.cc_parent -- Parent Cost Center -- Defect 9274
                                 || '|'   ||lr_gl_balances.segment2 -- Cost Center
                                 || '|'   ||lr_gl_balances.segment4 -- Location
                                 || '|'   ||lr_gl_balances.segment6 -- LOB
                                 || '|'   ||lr_gl_balances.ytd_trans_bal  -- NET YTD Translated Balance
                                 );
      EXCEPTION
      WHEN OTHERS THEN
        ln_error_flag := 1;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while writing into Text file. '|| SQLERRM);
      END;
    END LOOP;
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Company: ' || lc_previous_company ||'  Number of rows extracted: '||ln_com_count);
    lc_previous_company := NULL;
    ln_com_count := 0;
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Set of Books: ' || p_sob_name || ' Period: ' || p_period_name ||' Currency: '||'CAD'|| ' Total Posted Amount: ' || ln_sob_ytd_trans_bal_cad);        --Added for Defect 11050
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Set of Books: ' || p_sob_name || ' Period: ' || p_period_name ||' Currency: '||'USD'|| ' Total Posted Amount: ' || ln_sob_ytd_trans_bal_usd);        --Added for Defect 11050
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Set of Books: ' || p_sob_name || ' Period: ' || p_period_name ||' Currency: '||'STAT'|| ' Total Posted Amount: ' || ln_sob_ytd_trans_bal_stat);        --Added for Defect 11050
    UTL_FILE.fclose(lt_file);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'');
    IF ln_error_flag = 0 THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'The GL Balances have been written into the file successfully.');
    END IF;
/*    FOR lr_bal_rec_num IN lcu_bal_rec_num(lr_set_of_books.set_of_books_id)
    LOOP
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Company: ' || lr_bal_rec_num.segment1
                                       || '   Number of Rows extracted: ' || lr_bal_rec_num.cnt);
    END LOOP;*/
    --------------- Call the Common file copy Program to Copy the file to $XXFIN_DATA/ftp/out/hyperion-------------
    lc_source_file_name  := lc_source_file_path || '/' || lc_file_name;
    lc_dest_file_name    := lc_dest_file_path   || '/' || lc_file_name;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'');
    FND_FILE.PUT_LINE(FND_FILE.LOG,'The Created File Name     : ' || lc_source_file_name);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'The File Copied  Path     : ' || lc_dest_file_name);

    ln_req_id1 := FND_REQUEST.SUBMIT_REQUEST ('xxfin'
                                             ,'XXCOMFILCOPY'
                                             ,''
                                             ,''
                                             ,FALSE
                                             ,lc_source_file_name
                                             ,lc_dest_file_name
                                             ,NULL
                                             ,NULL
                                            );
    FND_FILE.PUT_LINE(FND_FILE.LOG,'');
    FND_FILE.PUT_LINE(FND_FILE.LOG,'The File was Copied into ' ||  lc_dest_file_path
                                   || '. Request id : ' || ln_req_id1);
    --------- Call the Common file copy Program to archive the file into $XXFIN_ARCHIVE/outbound -------
    lc_dest_file_name    := lc_archive_file_path || '/' || SUBSTR(lc_file_name,1,LENGTH(lc_file_name) - 4)
                                                 || TO_CHAR(SYSDATE, 'DD-MON-YYYYHHMMSS') || '.txt';
    FND_FILE.PUT_LINE(FND_FILE.LOG,'');
    FND_FILE.PUT_LINE(FND_FILE.LOG,'The Created File Name    : ' || lc_source_file_name);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'The Archived File Path   : ' || lc_dest_file_name);
    ln_req_id2 := FND_REQUEST.SUBMIT_REQUEST ('xxfin'
                                             ,'XXCOMFILCOPY'
                                             ,''
                                             ,''
                                             ,FALSE
                                             ,lc_source_file_name
                                             ,lc_dest_file_name
                                             ,NULL
                                             ,NULL
                                            );
    FND_FILE.PUT_LINE(FND_FILE.LOG,'');
    FND_FILE.PUT_LINE(FND_FILE.LOG,'The File was Archived into ' ||  lc_archive_file_path
                                      || '. Request id : ' || ln_req_id2);
    COMMIT;
    ----------- Wait for the Common file copy Program to Complete -----------
    lb_req_status1 := FND_CONCURRENT.WAIT_FOR_REQUEST(request_id  => ln_req_id1
                                                     ,interval    => '2'
                                                     ,max_wait    => ''
                                                     ,phase       => lc_phase
                                                     ,status      => lc_status
                                                     ,dev_phase   => lc_devphase
                                                     ,dev_status  => lc_devstatus
                                                     ,message     => lc_message
                                                    );
    lb_req_status2 := FND_CONCURRENT.WAIT_FOR_REQUEST(request_id  => ln_req_id2
                                                     ,interval    => '2'
                                                     ,max_wait    => ''
                                                     ,phase       => lc_phase
                                                     ,status      => lc_status
                                                     ,dev_phase   => lc_devphase
                                                     ,dev_status  => lc_devstatus
                                                     ,message     => lc_message
                                                    );
    -------------- Remove the File from  XXFIN_OUTBOUND ------------------
    BEGIN
      UTL_FILE.FREMOVE(lc_file_path, lc_file_name);
    EXCEPTION
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while Removing the file '
                                        || lc_file_path || '/' || lc_file_name || '. ' || SQLERRM);
    END;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'*************************************************************');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'*************************************************************');
  END LOOP;
------------------- End the program in warning if Out of date Translations and Null translated balances exists------
    IF ln_old_trans > 0 THEN
      x_ret_code := 1;
      x_err_buff := 'Out of date Translations exist in the extraction run';
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Out of date Translations exist in the extraction run');
    END IF;
    IF ln_trans_balances = 0 THEN
      x_ret_code := 1;
      x_err_buff := 'Null translated balances exist in the extraction run';
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Null translated balances exist in the extraction run.');
    END IF;
  --------Call the Daily Balance Extract Program-------------
  ln_req_id3 := FND_REQUEST.SUBMIT_REQUEST ('xxfin'
                                           ,'XXODGLDBALEXT'
                                           ,''
                                           ,''
                                           ,FALSE
                                           ,'D'
                                           ,'ALL'
                                           ,p_year
                                           ,p_period_name
                                           ,p_acc_rolup_grp_name
                                           ,p_cc_rolup_grp_name
                                           );
EXCEPTION
WHEN OTHERS THEN
  IF UTL_FILE.is_open(lt_file) THEN
    UTL_FILE.fclose(lt_file);
  END IF;
  FND_MESSAGE.SET_NAME('XXFIN','XX_GL_0006_BAL_EXT_OTHERS');
  FND_MESSAGE.SET_TOKEN('COL','GL Balance');
  lc_error_msg := FND_MESSAGE.GET;
  x_ret_code := 2;
  XX_COM_ERROR_LOG_PUB.LOG_ERROR (p_program_type             => 'CONCURRENT PROGRAM'
                                  ,p_program_name            => 'OD: GL Monthly Balance Extract Program'
                                  ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                  ,p_module_name             => 'GL'
                                  ,p_error_location          => 'Oracle Error '||SQLERRM
                                  ,p_error_message_count     => ln_msg_cnt + 1
                                  ,p_error_message_code      => 'E'
                                  ,p_error_message           => lc_error_msg
                                  ,p_error_message_severity  => 'Major'
                                  ,p_notify_flag             => 'N'
                                  ,p_object_type             => 'GL Balance Extract'
                                 );
END GL_BAL_MONTHLY_EXTRACT;

--Added the below procedure GL_BAL_MONTHLY_EXTRACT_CAD_MTD for Defect# 7916 by Mohammed Appas on 07-Oct-2010
-- +====================================================================+
-- | Name : GL_BAL_MONTHLY_EXTRACT_CAD_MTD                              |
-- | Description : extracts the ledger balances and COA segments on a   |
-- |               monthly basis from Oracle General Ledger for CA      |
-- |               Set of books alone with MTD Column and copies on to  |
-- |               a data file                                          |
-- | Parameters :  x_err_buff, x_ret_code, p_sob_name, p_year,          |
-- |               p_period_name                                        |
-- | Returns :     Return Code, Error buff                              |
-- +====================================================================+
PROCEDURE GL_BAL_MONTHLY_EXTRACT_CAD_MTD(x_err_buff      OUT NOCOPY VARCHAR2
                                        ,x_ret_code     OUT NUMBER
                                        ,p_year         IN  NUMBER
                                        ,p_period_name  IN  VARCHAR2
                                        ,p_acc_rolup_grp_name   IN VARCHAR2
                                        ,p_cc_rolup_grp_name    IN VARCHAR2
                                        )
IS
  lc_period_num            VARCHAR2(2);
  lc_file_name             VARCHAR2(100);
  ln_old_trans             NUMBER := 0;
  ln_trans_balances        NUMBER := 0;
  ln_cc_value_set_id       NUMBER := 0;
  ln_acct_value_set_id     NUMBER := 0;
  ln_set_of_books_id       NUMBER := 0;
  lb_req_status1           BOOLEAN;
  lb_req_status2           BOOLEAN;
  lc_file_path             VARCHAR2(500) := 'XXFIN_DAILY';   --Modified the value from 'XXFIN_OUTBOUND' to XXFIN_DAILY on 18-Nov-10 by Mohammed Appas A
  lc_source_file_path      VARCHAR2(500);
  lc_dest_file_path        VARCHAR2(500) := '$XXFIN_DATA/ftp/out/hyperion';
  lc_archive_file_path     VARCHAR2(500) := '$XXFIN_ARCHIVE/outbound';
  lc_source_file_name      VARCHAR2(1000);
  lc_dest_file_name        VARCHAR2(1000);
  lc_phase                 VARCHAR2(50);
  lc_status                VARCHAR2(50);
  lc_devphase              VARCHAR2(50);
  lc_devstatus             VARCHAR2(50);
  lc_message               VARCHAR2(50);
  lc_error_msg             VARCHAR2(4000);
  lc_scenario_print        VARCHAR2(200);
  lc_layer_print           VARCHAR2(200);
  lc_scenario              VARCHAR2(200);
  lc_layer                 VARCHAR2(200);
  ln_req_id1               NUMBER(10) := 0;
  --ln_req_id2               NUMBER(10) := 0;       --Commented on 18-Nov-10 by Mohammed Appas A
  ln_req_id3               NUMBER(10) := 0;
  ln_msg_cnt               NUMBER := 0;
  lt_file                  UTL_FILE.FILE_TYPE;
  ln_buffer                BINARY_INTEGER := 32767;
  ln_appl_id           fnd_application.application_id%TYPE;
  ln_sob_ytd_trans_bal_cad  NUMBER := 0;
  ln_sob_ytd_trans_bal_usd  NUMBER := 0;
  ln_sob_ytd_trans_bal_stat NUMBER := 0;
  ln_com_count              NUMBER := 0;
  lc_previous_company  gl_code_combinations.segment1%TYPE := NULL;
  ln_acc_rollup_grp        NUMBER := 0;
  ln_cc_rollup_grp         NUMBER := 0;
  ln_error_flag            NUMBER := 0;
  lc_parent_acc            CONSTANT fnd_flex_value_norm_hierarchy.parent_flex_value%TYPE := 'P8000000';
  --------------Cursor Query for fetching the Set of Books ------------
  CURSOR lcu_set_of_books
  IS
  --commented by kiran V(2.5) as per R12 Retrofit Change
  /*SELECT GSB.set_of_books_id
        ,GSB.short_name
        ,GSB.name
        ,GSB.currency_code
        ,GSB.chart_of_accounts_id
  FROM   gl_sets_of_books GSB
  WHERE  GSB.attribute1 = 'Y'
  AND    GSB.set_of_books_id = fnd_profile.value('GL_SET_OF_BKS_ID');*/
  --added by kiran V(2.5) as per R12 Retrofit Change
  SELECT GL.ledger_id
        ,GL.short_name
        ,GL.name
        ,GL.currency_code
        ,GL.chart_of_accounts_id
  FROM   gl_ledgers GL
  WHERE  GL.attribute1 = 'Y'
  AND    GL.ledger_id = fnd_profile.value('GL_SET_OF_BKS_ID');
  --ended by kiran V(2.5) as per R12 Retrofit Change
  --------Cursor Query for extracting GL Balances---------
  CURSOR lcu_gl_balances(p_set_of_books_id   IN NUMBER
                        ,p_currency_code     IN VARCHAR2
                        ,p_acct_value_set_id IN NUMBER
                        ,p_cc_value_set_id   IN NUMBER
                        ,p_acc_rollup_grp    IN NUMBER
                        ,p_cc_rollup_grp     IN NUMBER
                        ,p_coa_id            IN NUMBER)
  IS
--Query to fetch the records where the parents exist for both account and cost center
  SELECT   /*+ leading(GLB) no_merge(AC) no_merge(AC1) no_merge(CC1) */
          GLB.period_name
         ,INITCAP(TO_CHAR(TO_DATE(GLB.period_name,'MON-RR'),'MON')) period
         ,GLB.actual_flag
         ,GLB.period_year
         ,TO_CHAR(TO_DATE(GLB.period_year,'RRRR'),'RR') year
         ,GCC.segment1 COMPANY
         ,GCC.segment2
         ,GCC.segment3
         ,AC_PAR.parent_flex_value acct_parent
         ,CC_PAR.parent_flex_value cc_parent
         ,AC.description acct_description
         ,GCC.segment4
         ,GCC.segment5
         ,GCC.segment6
         ,GCC.segment7
         ,GLB.currency_code
         ,GLB.translated_flag
         ,(GLB.begin_balance_dr-GLB.begin_balance_cr + GLB.period_net_dr-GLB.period_net_cr) ytd_trans_bal
         ,(GLB.period_net_dr-GLB.period_net_cr) mtd_bal
  FROM   gl_balances  GLB
         ,gl_code_combinations GCC
         ,fnd_flex_values_vl AC
         ,fnd_flex_values_vl AC1
         ,fnd_flex_value_norm_hierarchy AC_PAR
         ,fnd_flex_values_vl CC1
         ,fnd_flex_value_norm_hierarchy CC_PAR
  --WHERE  GLB.set_of_books_id = p_set_of_books_id                                --commented by kiran V(2.5) as per R12 Retrofit Change
  WHERE  GLB.ledger_id = p_set_of_books_id                                        --added by kiran V(2.5) as per R12 Retrofit Change
  AND    GLB.period_name = p_period_name
  AND    ((GLB.translated_flag IN ('Y','N') AND GLB.currency_code = 'USD')
           OR
          ((GLB.translated_flag IS NULL AND GLB.currency_code = 'STAT')
            OR
           (GLB.translated_flag IS NULL AND GLB.currency_code = 'USD' AND p_currency_code = 'USD')
          )
         )
  AND    GLB.actual_flag = 'A'
  AND    GCC.chart_of_accounts_id = p_coa_id
  AND    GCC.template_id IS NULL
  AND    GCC.code_combination_id   = GLB.code_combination_id
  AND    CC_PAR.parent_flex_value = CC1.flex_value
  AND    CC1.flex_value_set_id = p_cc_value_set_id
  AND    CC1.structured_hierarchy_level = p_cc_rollup_grp
  AND    CC_PAR.flex_value_set_id = p_cc_value_set_id
  AND    GCC.segment2 BETWEEN CC_PAR.child_flex_value_low AND CC_PAR.child_flex_value_high
  AND    AC_PAR.parent_flex_value = AC1.flex_value
  AND    AC1.flex_value_set_id = p_acct_value_set_id
  AND    AC1.structured_hierarchy_level = p_acc_rollup_grp
  AND    AC.flex_value_set_id = p_acct_value_set_id
  AND    AC_PAR.flex_value_set_id = p_acct_value_set_id
  AND    AC.flex_value BETWEEN AC_PAR.child_flex_value_low AND AC_PAR.child_flex_value_high
  AND    AC.flex_value = gcc.segment3
  AND    AC1.enabled_flag = 'Y'
  AND    AC.enabled_flag = 'Y'
  AND    CC1.enabled_flag = 'Y'
  UNION ALL
  --Query to fetch values where account parent does not exist and cost center parent exist
  SELECT /*+ leading(GLB) no_merge(AC) no_merge(CC1)*/
         GLB.period_name
         ,INITCAP(TO_CHAR(TO_DATE(GLB.period_name,'MON-RR'),'MON')) period
         ,GLB.actual_flag
         ,GLB.period_year
         ,TO_CHAR(TO_DATE(GLB.period_year,'RRRR'),'RR') year
         ,GCC.segment1 COMPANY
         ,GCC.segment2
         ,GCC.segment3
         ,'' acct_parent
         ,CC_PAR.parent_flex_value cc_parent
         ,AC.description acct_description
         ,GCC.segment4
         ,GCC.segment5
         ,GCC.segment6
         ,GCC.segment7
         ,GLB.currency_code
         ,GLB.translated_flag
         ,(GLB.begin_balance_dr-GLB.begin_balance_cr + GLB.period_net_dr-GLB.period_net_cr) ytd_trans_bal
         ,(GLB.period_net_dr-GLB.period_net_cr) mtd_bal
  FROM   gl_balances  GLB
         ,gl_code_combinations GCC
         ,fnd_flex_values_vl AC
         ,fnd_flex_values_vl CC1
         ,fnd_flex_value_norm_hierarchy CC_PAR
  --WHERE  GLB.set_of_books_id = p_set_of_books_id                                --commented by kiran V(2.5) as per R12 Retrofit Change
  WHERE  GLB.ledger_id = p_set_of_books_id                                        --added by kiran V(2.5) as per R12 Retrofit Change
  AND    GLB.period_name = p_period_name
  AND    GCC.code_combination_id   = GLB.code_combination_id
  AND    ((GLB.translated_flag IN ('Y','N') AND GLB.currency_code = 'USD')
           OR
          ((GLB.translated_flag IS NULL AND GLB.currency_code = 'STAT')
            OR
           (GLB.translated_flag IS NULL AND GLB.currency_code = 'USD' AND p_currency_code = 'USD')
          )
         )
  AND    GLB.actual_flag = 'A'
  AND    GCC.template_id IS NULL
  AND    GCC.chart_of_accounts_id = p_coa_id
  AND    AC.flex_value_set_id = p_acct_value_set_id
  AND    AC.flex_value = GCC.segment3
  AND    AC.enabled_flag = 'Y'
  AND NOT EXISTS( SELECT /*+ use_hash(AC1 AC_PAR)*/ 1
                  FROM fnd_flex_value_norm_hierarchy AC_PAR , fnd_flex_values AC1
                  WHERE AC_PAR.flex_value_set_id = p_acct_value_set_id
                  AND GCC.segment3 BETWEEN AC_PAR.child_flex_value_low AND AC_PAR.child_flex_value_high
                  AND AC1.flex_value = AC_PAR.parent_flex_value
                  AND AC1. flex_value_set_id = p_acct_value_set_id
                  AND AC1.structured_hierarchy_level = p_acc_rollup_grp
                  AND AC1.enabled_flag = 'Y'
                )
  AND    CC_PAR.parent_flex_value = CC1.flex_value
  AND    CC1.flex_value_set_id = p_cc_value_set_id
  AND    CC1.structured_hierarchy_level = p_cc_rollup_grp
  AND    CC_PAR.flex_value_set_id = p_cc_value_set_id
  AND    GCC.segment2 BETWEEN CC_PAR.child_flex_value_low AND CC_PAR.child_flex_value_high
  UNION ALL
  --Query to fetch records where both cost center parent and account parent do not exist
  SELECT /*+ leading(GLB) no_merge(AC) */
         GLB.period_name
         ,INITCAP(TO_CHAR(TO_DATE(GLB.period_name,'MON-RR'),'MON')) period
         ,GLB.actual_flag
         ,GLB.period_year
         ,TO_CHAR(TO_DATE(GLB.period_year,'RRRR'),'RR') year
         ,GCC.segment1 COMPANY
         ,GCC.segment2
         ,GCC.segment3
         ,'' acct_parent
         ,'' cc_parent
         ,AC.description acct_description
         ,GCC.segment4
         ,GCC.segment5
         ,GCC.segment6
         ,GCC.segment7
         ,GLB.currency_code
         ,GLB.translated_flag
         ,(GLB.begin_balance_dr-GLB.begin_balance_cr + GLB.period_net_dr-GLB.period_net_cr) ytd_trans_bal
         ,(GLB.period_net_dr-GLB.period_net_cr) mtd_bal
  FROM   gl_balances  GLB
         ,gl_code_combinations GCC
         ,fnd_flex_values_vl AC
   --WHERE  GLB.set_of_books_id = p_set_of_books_id                               --commented by kiran V(2.5) as per R12 Retrofit Change
  WHERE  GLB.ledger_id = p_set_of_books_id                                        --added by kiran V(2.5) as per R12 Retrofit Change
  AND    GLB.period_name = p_period_name
  AND    GCC.code_combination_id   = GLB.code_combination_id
  AND    ((GLB.translated_flag IN ('Y','N') AND GLB.currency_code = 'USD')
           OR
          ((GLB.translated_flag IS NULL AND GLB.currency_code = 'STAT')
            OR
           (GLB.translated_flag IS NULL AND GLB.currency_code = 'USD' AND p_currency_code = 'USD')
          )
         )
  AND    GLB.actual_flag = 'A'
  AND    GCC.template_id IS NULL
  AND    GCC.chart_of_accounts_id = p_coa_id
  AND    AC.flex_value_set_id = p_acct_value_set_id
  AND    AC.flex_value = GCC.segment3
  AND    AC.enabled_flag = 'Y'
  AND NOT EXISTS( SELECT /*+ use_hash(AC1 AC_PAR)*/ 1
                  FROM fnd_flex_value_norm_hierarchy AC_PAR , fnd_flex_values AC1
                  WHERE AC_PAR.flex_value_set_id = p_acct_value_set_id
                  AND GCC.segment3 BETWEEN AC_PAR.child_flex_value_low AND AC_PAR.child_flex_value_high
                  AND AC1.flex_value = AC_PAR.parent_flex_value
                  AND AC1. flex_value_set_id = p_acct_value_set_id
                  AND AC1.structured_hierarchy_level = p_acc_rollup_grp
                  AND AC1.enabled_flag = 'Y'
                )
  AND NOT EXISTS( SELECT /*+ use_hash(CC1 CC_PAR)*/ 1
                  FROM fnd_flex_value_norm_hierarchy CC_PAR, fnd_flex_values CC1
                  WHERE CC_PAR.flex_value_set_id = p_cc_value_set_id
                  AND GCC.segment2 BETWEEN CC_PAR.child_flex_value_low AND CC_PAR.child_flex_value_high
                  AND CC1.flex_value = CC_PAR.parent_flex_value
                  AND CC1. flex_value_set_id = p_cc_value_set_id
                  AND CC1.structured_hierarchy_level = p_cc_rollup_grp
                  AND CC1.enabled_flag = 'Y'
                )
  UNION ALL
 --Query to fetch the records where parent account exists but parent cost center does not exist
  SELECT  /*+ leading(GLB) no_merge(AC) no_merge(AC1)*/
         GLB.period_name
         ,INITCAP(TO_CHAR(TO_DATE(GLB.period_name,'MON-RR'),'MON')) period
         ,GLB.actual_flag
         ,GLB.period_year
         ,TO_CHAR(TO_DATE(GLB.period_year,'RRRR'),'RR') year
         ,GCC.segment1 COMPANY
         ,GCC.segment2
         ,GCC.segment3
         ,AC_PAR.parent_flex_value acct_parent
         ,'' cc_parent
         ,AC.description acct_description
         ,GCC.segment4
         ,GCC.segment5
         ,GCC.segment6
         ,GCC.segment7
         ,GLB.currency_code
         ,GLB.translated_flag
         ,(GLB.begin_balance_dr-GLB.begin_balance_cr + GLB.period_net_dr-GLB.period_net_cr) ytd_trans_bal
         ,(GLB.period_net_dr-GLB.period_net_cr) mtd_bal
  FROM   gl_balances  GLB
         ,gl_code_combinations GCC
         ,fnd_flex_values_vl AC
         ,fnd_flex_values_vl AC1
         ,fnd_flex_value_norm_hierarchy AC_PAR
  --WHERE  GLB.set_of_books_id = p_set_of_books_id                                --commented by kiran V(2.5) as per R12 Retrofit Change
  WHERE  GLB.ledger_id = p_set_of_books_id                                        --added by kiran V(2.5) as per R12 Retrofit Change
  AND    GLB.period_name = p_period_name
  AND    GCC.code_combination_id   = GLB.code_combination_id
  AND    ((GLB.translated_flag IN ('Y','N') AND GLB.currency_code = 'USD')
           OR
          ((GLB.translated_flag IS NULL AND GLB.currency_code = 'STAT')
            OR
           (GLB.translated_flag IS NULL AND GLB.currency_code = 'USD' AND p_currency_code = 'USD')
          )
         )
  AND    GLB.actual_flag = 'A'
  AND    GCC.template_id IS NULL
  AND    GCC.chart_of_accounts_id = p_coa_id
  AND    AC_PAR.parent_flex_value = AC1.flex_value
  AND    AC1.flex_value_set_id = p_acct_value_set_id
  AND    AC1.structured_hierarchy_level = p_acc_rollup_grp
  AND    AC.flex_value_set_id = p_acct_value_set_id
  AND    AC_PAR.flex_value_set_id = p_acct_value_set_id
  AND    AC.flex_value BETWEEN AC_PAR.child_flex_value_low AND AC_PAR.child_flex_value_high
  AND    AC.flex_value = gcc.segment3
  AND    AC.enabled_flag = 'Y'
  AND    AC1.enabled_flag = 'Y'
  AND NOT EXISTS( SELECT  /*+ use_hash(CC1 CC_PAR)*/  1
                  FROM fnd_flex_value_norm_hierarchy CC_PAR, fnd_flex_values CC1
                  WHERE CC_PAR.flex_value_set_id = p_cc_value_set_id
                  AND   GCC.segment2 BETWEEN CC_PAR.child_flex_value_low AND CC_PAR.child_flex_value_high
                  AND   CC1.flex_value = CC_PAR.parent_flex_value
                  AND   CC1. flex_value_set_id = p_cc_value_set_id
                  AND   CC1.structured_hierarchy_level = p_cc_rollup_grp
                  AND   CC1.enabled_flag = 'Y'
                )
  ORDER BY COMPANY;

BEGIN
  BEGIN
    SELECT application_id
    INTO   ln_appl_id
    FROM   fnd_application
    WHERE  application_short_name = 'SQLGL';
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching the application ID. '
                                    || SQLERRM);
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching the application ID. '
                                    || SQLERRM);
  END;
  BEGIN
    --commented by kiran V(2.5) as per R12 Retrofit Change
    /*SELECT GSB.set_of_books_id
    INTO ln_set_of_books_id
    FROM   gl_sets_of_books GSB
    WHERE  GSB.attribute1 = 'Y'
    AND    GSB.set_of_books_id = fnd_profile.value('GL_SET_OF_BKS_ID');*/
    --added by kiran V(2.5) as per R12 Retrofit Change
    SELECT GL.ledger_id
    INTO   ln_set_of_books_id
    FROM   gl_ledgers GL
    WHERE  GL.attribute1 = 'Y'
    AND    GL.ledger_id = fnd_profile.value('GL_SET_OF_BKS_ID');
    --ended by kiran V(2.5) as per R12 Retrofit Change
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching the Set of Books Id of CA'
                                    || SQLERRM);
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching the Set of Books Id of CA'
                                    || SQLERRM);
  END;
  BEGIN
    SELECT directory_path
    INTO   lc_source_file_path
    FROM   dba_directories
    WHERE  directory_name = lc_file_path;
  EXCEPTION
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching the File Path XXFIN_OUTBOUND. '
                                    || SQLERRM);
  END;
  x_ret_code := 0;
  FOR lr_set_of_books IN lcu_set_of_books
  LOOP
    lc_previous_company := NULL;
    ln_com_count := 0;
    ln_sob_ytd_trans_bal_cad := 0;
    ln_sob_ytd_trans_bal_usd := 0;
    ln_sob_ytd_trans_bal_stat := 0;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'*************************************************************');
    FND_FILE.PUT_LINE(FND_FILE.LOG,'SOB Name     : ' || lr_set_of_books.short_name);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Currency     : ' || lr_set_of_books.currency_code);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Period Name  : ' || p_period_name);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'-------------------------------------------------------------');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'*************************************************************');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'SOB Name     : ' || lr_set_of_books.short_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Currency     : ' || lr_set_of_books.currency_code);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Period Name  : ' || p_period_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------------------------');
    -----------Query for fetching period_num for the current period---------
    BEGIN
      SELECT LPAD(GP.period_num, 2,0)
      INTO   lc_period_num
      FROM   gl_period_statuses GP
      WHERE  period_name = p_period_name
      --AND    GP.set_of_books_id = lr_set_of_books.set_of_books_id                                    --commented by kiran V(2.5) as per R12 Retrofit Change
      AND    GP.ledger_id = lr_set_of_books.ledger_id                                                  --added by kiran V(2.5) as per R12 Retrofit Change
      AND    GP.application_id = ln_appl_id;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Exception raised while trying to find period number.');
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while trying to find period number'
                                    || SQLERRM);
    END;
    lc_file_name := 'Act' || TO_CHAR(TO_DATE(p_period_name,'MON-YY'),'Mon') || 'CAD_USDFY' || TO_CHAR(TO_DATE(p_period_name,'MON-YY'),'YY') || '_MTD.txt';
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The GL Balance Extract File Name : ' || lc_file_name);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'The Created File Path               : ' || lc_file_path);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'The Destination File Path           : ' || lc_dest_file_path);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'*************************************************************');
    BEGIN
      lt_file := UTL_FILE.fopen(lc_file_path, lc_file_name,'w',ln_buffer);
    EXCEPTION
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while Opening the file. '|| SQLERRM);
    END;
    --------Query for fetching flex_value_set_ids for Accounts and Cost Centers---------
    BEGIN
    SELECT distinct FFV_CC.flex_value_set_id
           ,FFV_AC.flex_value_set_id
    INTO   ln_cc_value_set_id
           ,ln_acct_value_set_id
    FROM   fnd_flex_value_sets FFV_CC
           ,fnd_id_flex_segments FSG_CC
           ,fnd_flex_value_sets FFV_AC
           ,fnd_id_flex_segments FSG_AC
    WHERE  FSG_CC.segment_name = 'Cost Center'
    AND    FSG_CC.flex_value_set_id = FFV_CC.flex_value_set_id
    AND    FSG_CC.id_flex_num = lr_set_of_books.chart_of_accounts_id
    AND    FSG_AC.segment_name = 'Account'
    AND    FSG_AC.flex_value_set_id = FFV_AC.flex_value_set_id
    AND    FSG_AC.id_flex_num = lr_set_of_books.chart_of_accounts_id;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Value Set IDs not found for Account and Cost Center. '
                                      || SQLERRM);
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching Value Set IDs for Account and Cost Center. '
                                      || SQLERRM);
    END;
  --------Query for fetching hierarchy_id for Report Line    ---------
    BEGIN
      SELECT ACC.hierarchy_id
      INTO   ln_acc_rollup_grp
      FROM   fnd_flex_hierarchies_vl ACC
      WHERE  ACC.hierarchy_code = p_acc_rolup_grp_name
      AND    ACC.flex_value_set_id = ln_acct_value_set_id;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Hierarchy IDs not found for Report Line. '
                                      || SQLERRM);
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching Hierarchy IDs not found for Report Line. '
                                      || SQLERRM);
    END;
    --------Query for fetching hierarchy_id for External       ---------
    BEGIN
      SELECT CC.hierarchy_id
      INTO   ln_cc_rollup_grp
      FROM   fnd_flex_hierarchies_vl CC
      WHERE  CC.hierarchy_code = p_cc_rolup_grp_name
      AND    CC.flex_value_set_id = ln_cc_value_set_id;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Hierarchy IDs not found for External. '
                                      || SQLERRM);
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching Hierarchy IDs not found for External. '
                                      || SQLERRM);
    END;

  --Added the below BOLCK on 24-Nov-2010 by Mohammed Appas
  --------Fetching value for Scenario from translation --------
  BEGIN
    SELECT XFTV.target_value1
    INTO lc_scenario
    FROM xx_fin_translatedefinition  XFTD
        ,xx_fin_translatevalues      XFTV
    WHERE XFTV.translate_id = XFTD.translate_id
    AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
    AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
    AND XFTV.source_value1 = 'Scenario'
    AND XFTD.translation_name = 'XX_GL_1360_BALANCE_EXT'
    AND XFTV.enabled_flag = 'Y'
    AND XFTD.enabled_flag = 'Y';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'No values found for Scenario from translation   ');
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching values from translation for Scenario    '
                                      || SQLERRM);
  END;

  --Added the below BOLCK on 24-Nov-2010 by Mohammed Appas
  -------- Fetching value for Layer from translation --------
  BEGIN
    SELECT XFTV.target_value1
    INTO lc_layer
    FROM xx_fin_translatedefinition  XFTD
        ,xx_fin_translatevalues      XFTV
    WHERE XFTV.translate_id = XFTD.translate_id
    AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
    AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
    AND XFTV.source_value1 = 'Layer'
    AND XFTD.translation_name = 'XX_GL_1360_BALANCE_EXT'
    AND XFTV.enabled_flag = 'Y'
    AND XFTD.enabled_flag = 'Y';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'No values found for Layer from translation ');
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching values from translation for Layer    '
                                      || SQLERRM);
  END;

      FOR lr_gl_balances IN lcu_gl_balances(ln_set_of_books_id,lr_set_of_books.currency_code,ln_acct_value_set_id,ln_cc_value_set_id,ln_acc_rollup_grp,ln_cc_rollup_grp,lr_set_of_books.chart_of_accounts_id)
      LOOP
        IF (lc_previous_company <> lr_gl_balances.COMPANY) THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Company: ' || lc_previous_company ||'  Number of rows extracted: '||ln_com_count);
          ln_com_count := 0;
        END IF;
           ln_com_count := ln_com_count+1;
           lc_previous_company := lr_gl_balances.COMPANY;
           IF(lr_gl_balances.currency_code = 'CAD') THEN
              ln_sob_ytd_trans_bal_cad := ln_sob_ytd_trans_bal_cad + lr_gl_balances.ytd_trans_bal;
           ELSIF(lr_gl_balances.currency_code = 'USD')THEN
              ln_sob_ytd_trans_bal_usd := ln_sob_ytd_trans_bal_usd + lr_gl_balances.ytd_trans_bal;
           ELSE
              ln_sob_ytd_trans_bal_stat := ln_sob_ytd_trans_bal_stat + lr_gl_balances.ytd_trans_bal;
           END IF;
        IF (lr_set_of_books.currency_code <> 'USD') THEN
           IF (lr_gl_balances.translated_flag = 'N') THEN
              ln_old_trans := ln_old_trans+1;
           END IF;
           IF (lr_gl_balances.translated_flag = 'Y') THEN
              ln_trans_balances := ln_trans_balances+1;
           END IF;
        END IF;
        IF (SUBSTR(lr_gl_balances.segment3,1,1) = '8') THEN
          lr_gl_balances.acct_parent := lc_parent_acc;
        END IF;
        IF (lr_gl_balances.acct_parent IS NULL) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Missing Parent account for the - Account: '|| lr_gl_balances.segment3);
        END IF;
        IF (lr_gl_balances.cc_parent IS NULL) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Missing Parent Cost Center for the - Cost Center: '|| lr_gl_balances.segment2);
        END IF;

        ------------------ Writing GL Balances into text file -------------------
        BEGIN
           -- Commented on 24-Nov-2010 by Mohammed Appas A
          /*UTL_FILE.PUT_LINE(lt_file, lr_set_of_books.short_name
                                   || '|'   ||lr_gl_balances.actual_flag
                                   || '|'   ||lr_gl_balances.period_name
                                   || '|'   ||lr_gl_balances.period_year
                                   || '|'   ||lr_gl_balances.currency_code
                                   || '|'   ||lr_gl_balances.COMPANY -- Company
                                   || '|'   ||lr_gl_balances.segment5 -- Intercompany
                                   || '|'   ||lr_gl_balances.acct_parent -- Parent Account
                                   || '|'   ||lr_gl_balances.segment3 -- Account
                                   || '|'   ||lr_gl_balances.acct_description -- Account Description
                                   || '|'   ||lr_gl_balances.cc_parent -- Parent Cost Center
                                   || '|'   ||lr_gl_balances.segment2 -- Cost Center
                                   || '|'   ||lr_gl_balances.segment4 -- Location
                                   || '|'   ||lr_gl_balances.segment6 -- LOB
                                   || '|'   ||lr_gl_balances.mtd_bal  -- NET MTD Translated Balance
                                   );*/
             -- Added on 24-Nov-2010 by Mohammed Appas A
          UTL_FILE.PUT_LINE(lt_file,lc_scenario                                -- Scenario
                               || '|'   ||lr_gl_balances.period                -- Period
                               || '|'   ||'FY'||lr_gl_balances.year            -- Year
                               || '|'   ||lr_gl_balances.company               -- Company
                               || '|'   ||lr_gl_balances.segment3              -- Account
                               || '|'   ||lr_gl_balances.segment2              -- Cost Center
                               || '|'   ||lr_gl_balances.segment6              -- LOB
                               || '|'   ||lr_gl_balances.segment4              -- Location
                               || '|'   ||lr_gl_balances.currency_code         -- Currency
                               || '|'   ||lc_layer                             -- Layer
                               || '|'   ||lr_gl_balances.ytd_trans_bal         -- NET YTD Balance(Amount)
                           );
        EXCEPTION
        WHEN OTHERS THEN
          ln_error_flag := 1;
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while writing into Text file. '|| SQLERRM);
        END;
      END LOOP;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Company: ' || lc_previous_company ||'  Number of rows extracted: '||ln_com_count);
      lc_previous_company := NULL;
      ln_com_count := 0;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Set of Books: ' || 'CA_CAD_P' || ' Period: ' || p_period_name ||' Currency: '||'CAD'|| ' Total Posted Amount: ' || ln_sob_ytd_trans_bal_cad);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Set of Books: ' || 'CA_CAD_P' || ' Period: ' || p_period_name ||' Currency: '||'USD'|| ' Total Posted Amount: ' || ln_sob_ytd_trans_bal_usd);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Set of Books: ' || 'CA_CAD_P' || ' Period: ' || p_period_name ||' Currency: '||'STAT'|| ' Total Posted Amount: ' || ln_sob_ytd_trans_bal_stat);
      UTL_FILE.fclose(lt_file);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'');
      IF ln_error_flag = 0 THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'The GL Balances have been written into the file successfully.');
      END IF;
      --------------- Call the Common file copy Program to Copy the file to $XXFIN_DATA/ftp/out/hyperion-------------
      lc_source_file_name  := lc_source_file_path || '/' || lc_file_name;
      lc_dest_file_name    := lc_dest_file_path   || '/' || lc_file_name;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'The Created File Name     : ' || lc_source_file_name);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'The File Copied  Path     : ' || lc_dest_file_name);

      ln_req_id1 := FND_REQUEST.SUBMIT_REQUEST ('xxfin'
                                               ,'XXCOMFILCOPY'
                                               ,''
                                               ,''
                                               ,FALSE
                                               ,lc_source_file_name
                                               ,lc_dest_file_name
                                               ,NULL
                                               ,NULL
                                              );
      FND_FILE.PUT_LINE(FND_FILE.LOG,'');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'The File was Copied into ' ||  lc_dest_file_path
                                     || '. Request id : ' || ln_req_id1);
      --------- Call the Common file copy Program to archive the file into $XXFIN_ARCHIVE/outbound -------
      --Commented on 18-Nov-10 by Mohammed Appas A
      /*lc_dest_file_name    := lc_archive_file_path || '/' || SUBSTR(lc_file_name,1,LENGTH(lc_file_name) - 4)
                                                   || TO_CHAR(SYSDATE, 'DD-MON-YYYYHHMMSS') || '.txt';
      FND_FILE.PUT_LINE(FND_FILE.LOG,'');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'The Created File Name    : ' || lc_source_file_name);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'The Archived File Path   : ' || lc_dest_file_name);
      ln_req_id2 := FND_REQUEST.SUBMIT_REQUEST ('xxfin'
                                               ,'XXCOMFILCOPY'
                                               ,''
                                               ,''
                                               ,FALSE
                                               ,lc_source_file_name
                                               ,lc_dest_file_name
                                               ,NULL
                                               ,NULL
                                              );
      FND_FILE.PUT_LINE(FND_FILE.LOG,'');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'The File was Archived into ' ||  lc_archive_file_path
                                        || '. Request id : ' || ln_req_id2);*/
      COMMIT;
      ----------- Wait for the Common file copy Program to Complete -----------
      lb_req_status1 := FND_CONCURRENT.WAIT_FOR_REQUEST(request_id  => ln_req_id1
                                                       ,interval    => '2'
                                                       ,max_wait    => ''
                                                       ,phase       => lc_phase
                                                       ,status      => lc_status
                                                       ,dev_phase   => lc_devphase
                                                       ,dev_status  => lc_devstatus
                                                       ,message     => lc_message
                                                      );
      -- Commented on 18-Nov-10 by Mohammed Appas A
      /*lb_req_status2 := FND_CONCURRENT.WAIT_FOR_REQUEST(request_id  => ln_req_id2
                                                       ,interval    => '2'
                                                       ,max_wait    => ''
                                                       ,phase       => lc_phase
                                                       ,status      => lc_status
                                                       ,dev_phase   => lc_devphase
                                                       ,dev_status  => lc_devstatus
                                                       ,message     => lc_message
                                                      );
      -------------- Remove the File from  XXFIN_DAILY ------------------
      BEGIN
        UTL_FILE.FREMOVE(lc_file_path, lc_file_name);
      EXCEPTION
      WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while Removing the file '
                                          || lc_file_path || '/' || lc_file_name || '. ' || SQLERRM);
      END;*/
      FND_FILE.PUT_LINE(FND_FILE.LOG,'*************************************************************');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'*************************************************************');
    END LOOP;
------------------- End the program in warning if Out of date Translations and Null translated balances exists------
  IF ln_old_trans > 0 THEN
    x_ret_code := 1;
    x_err_buff := 'Out of date Translations exist in the extraction run';
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Out of date Translations exist in the extraction run');
  END IF;
  IF ln_trans_balances = 0 THEN
    x_ret_code := 1;
    x_err_buff := 'Null translated balances exist in the extraction run';
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Null translated balances exist in the extraction run.');
  END IF;
  --------Call the Daily Balance Extract Program-------------
  ln_req_id3 := FND_REQUEST.SUBMIT_REQUEST ('xxfin'
                                           ,'XXODGLDBALEXT'
                                           ,''
                                           ,''
                                           ,FALSE
                                           ,'D'
                                           ,'ALL'
                                           ,p_year
                                           ,p_period_name
                                           ,p_acc_rolup_grp_name
                                           ,p_cc_rolup_grp_name
                                           );
EXCEPTION
WHEN OTHERS THEN
  IF UTL_FILE.is_open(lt_file) THEN
    UTL_FILE.fclose(lt_file);
  END IF;
  FND_MESSAGE.SET_NAME('XXFIN','XX_GL_0006_BAL_EXT_OTHERS');
  FND_MESSAGE.SET_TOKEN('COL','GL Balance');
  lc_error_msg := FND_MESSAGE.GET;
  x_ret_code := 2;
  XX_COM_ERROR_LOG_PUB.LOG_ERROR (p_program_type             => 'CONCURRENT PROGRAM'
                                  ,p_program_name            => 'OD: GL Monthly Balance MTD Extract Program'
                                  ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                  ,p_module_name             => 'GL'
                                  ,p_error_location          => 'Oracle Error '||SQLERRM
                                  ,p_error_message_count     => ln_msg_cnt + 1
                                  ,p_error_message_code      => 'E'
                                  ,p_error_message           => lc_error_msg
                                  ,p_error_message_severity  => 'Major'
                                  ,p_notify_flag             => 'N'
                                  ,p_object_type             => 'GL Balance Extract'
                                 );
END GL_BAL_MONTHLY_EXTRACT_CAD_MTD;
--End of Defect# 7916

-- +====================================================================+
-- | Name : GL_BALANCE_EXTRACT                                          |
-- | Description : calls the daily extract program or the monthly       |
-- |               extract program depending on the value of the        |
-- |               p_program parameter                                  |
-- | Parameters :  x_err_buff, x_ret_code, p_program, p_sob_name,       |
-- |               p_year, p_period_name                                |
-- | Returns :     Returns Code                                         |
-- |               Error Message                                        |
-- +====================================================================+
PROCEDURE GL_BALANCE_EXTRACT(x_err_buff         OUT NOCOPY VARCHAR2
                             ,x_ret_code        OUT NOCOPY NUMBER
                             ,p_program         IN  VARCHAR2
                             ,p_sob_name        IN  VARCHAR2
                             ,p_year            IN  NUMBER
                             ,p_period_name     IN  VARCHAR2
                             ,p_acc_rolup_grp_name   IN VARCHAR2
                             ,p_cc_rolup_grp_name    IN VARCHAR2
                            )
IS
BEGIN
  IF p_program = 'M' THEN
    GL_BAL_MONTHLY_EXTRACT(x_err_buff, x_ret_code, p_sob_name, p_year, p_period_name,p_acc_rolup_grp_name,p_cc_rolup_grp_name);
  ELSIF p_program = 'Y' THEN
    GL_BAL_MONTHLY_EXTRACT_CAD_MTD(x_err_buff, x_ret_code, p_year, p_period_name,p_acc_rolup_grp_name,p_cc_rolup_grp_name);
  ELSE
    GL_BAL_DAILY_EXTRACT(p_sob_name, p_year, p_period_name,p_acc_rolup_grp_name,p_cc_rolup_grp_name);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Program ended due to an unexpected error. ' || SQLERRM);
  x_ret_code := 2;
END GL_BALANCE_EXTRACT;


END XX_GL_BALANCE_EXT_PKG;
/
show error;