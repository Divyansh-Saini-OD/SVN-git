SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XXOD_TRANS_COMP_PKG AS
PROCEDURE populate_asset_details(
				p_book_type_code         VARCHAR2
				,p_transaction_type_code  VARCHAR2
				,p_company_low            VARCHAR2
				,p_company_high           VARCHAR2
				,p_category_low           VARCHAR2
				,p_category_high          VARCHAR2
            ,p_period_from            VARCHAR2
            ,p_period_to              VARCHAR2
            ,p_layout_type            VARCHAR2
				/*,p_period_from_date       DATE     -- Changed by Ganesan for the Period Informations are taken inside the Package itself
				,p_period_To_date         DATE
				,p_period_counter_low     NUMBER
				,p_period_counter_high    NUMBER
            ,p_layout_type            VARCHAR2*/
				)
AS
-- +============================================================================+
-- |                  Office Depot - Project Simplify                           |
-- |                  Wirpo / Office Depot                                      |
-- +============================================================================+
-- | Name             :  POPULATE_ASSET_DETAILS			                          |
-- | Description      :  This Procedure is used to Populate the Asset           |
-- |                     Details in xxod_fa_cost_comp_temp                      |
-- |                                                                            |
-- |Change Record:                                                              |
-- |===============                                                             |
-- |Version   Date        Author           Remarks                              |
-- |=======   ==========  =============    =====================================|
-- |DRAFT 1.0 26-AUG-2007  Senthil Kumar    Initial draft version               |
-- |DRAFT 1.1 15-Nov-2007  Ganesan          Fix for Defect 2315                 |
-- |                                        To improve the performance          |
-- |                                        , modified the package              |
-- |                                        to use Bulk Collect,Query based on  |
-- |                                        Transaction Type code               |
-- |DRAFT 1.2 13-dec-2007  Ganesan          Added the parameter p_layout_type   |
-- |                                        to insert the data based on the     |
-- |							                    layout type                         |
-- |DRAFT 1.3 24-JAN-2007  Ganesan         Changed the Parameters for the Period|
-- |                                       Informations are taken inside the    |
-- |                                       Package.Since the Period Informations|
-- |                                       changes with respect to the Book     |
-- |DRAFT 1.4 05-Aug-08     Ganesan         Changed the Cursor Queries merging  |
-- |                                       the cost and depreciation Queries in |
-- |                                       Asset Cursors for defect 8826 by     |
-- |                                       Ganesan                              |
-- +============================================================================+
-- Variable Declaration

-- Fix for Defect 2315

 TYPE asset_type           IS TABLE OF  xxod_fa_cost_comp_temp.asset%TYPE;
 TYPE company_type         IS TABLE OF  xxod_fa_cost_comp_temp.company%TYPE;
 TYPE transaction_type     IS TABLE OF  xxod_fa_cost_comp_temp.transaction%TYPE;
 TYPE category_type        IS TABLE OF  xxod_fa_cost_comp_temp.category%TYPE;
 TYPE asset_id_type        IS TABLE OF  xxod_fa_cost_comp_temp.asset_id%TYPE;
 TYPE book_type            IS TABLE OF  xxod_fa_cost_comp_temp.book%TYPE;
 TYPE pis_type             IS TABLE OF  xxod_fa_cost_comp_temp.pis%TYPE;
 TYPE amount_type          IS TABLE OF  xxod_fa_cost_comp_temp.amount%TYPE;
 TYPE corp_amount_type     IS TABLE OF  xxod_fa_cost_comp_temp.corp_amount%TYPE;
 TYPE deprn_amount_type    IS TABLE OF  xxod_fa_cost_comp_temp.amount%TYPE;
 TYPE corp_deprn_type      IS TABLE OF  xxod_fa_cost_comp_temp.corp_amount%TYPE;
 TYPE deprn_reserve_type   IS TABLE OF  xxod_fa_cost_comp_temp.amount%TYPE;
 TYPE corp_reserve_type    IS TABLE OF  xxod_fa_cost_comp_temp.corp_amount%TYPE;
 TYPE maj_cat_type         IS TABLE OF  xxod_fa_cost_comp_temp.maj_cat%TYPE;
 TYPE min_cat_type         IS TABLE OF  xxod_fa_cost_comp_temp.min_cat%TYPE;
 TYPE sub_minor_type       IS TABLE OF  xxod_fa_cost_comp_temp.sub_minor%TYPE;
 lt_asset                  asset_type;
 lt_company                company_type;
 lt_transaction            transaction_type;
 lt_category               category_type;
 lt_asset_id               asset_id_type;
 lt_book                   book_type;
 lt_pis                    pis_type;
 lt_amount                 amount_type         :=amount_type();
 lt_corp_amount            corp_amount_type    :=corp_amount_type() ;
 lt_deprn_amount           deprn_amount_type   :=deprn_amount_type();
 lt_corp_deprn             corp_deprn_type     :=corp_deprn_type();
 lt_deprn_reserve          deprn_reserve_type  :=deprn_reserve_type() ;
 lt_corp_reserve           corp_reserve_type   :=corp_reserve_type();
 lt_maj_cat                maj_cat_type        :=maj_cat_type();
 lt_min_cat                min_cat_type        :=min_cat_type();
 lt_sub_minor              sub_minor_type      :=sub_minor_type();
 lc_transfer_reclass_flag  VARCHAR2(1):='N';
 ld_period_from_date       DATE;
 ld_period_to_date         DATE;
 ln_period_from_cnt        NUMBER;
 ln_period_to_cnt          NUMBER;
 ld_corp_period_from_date  DATE;          -- Added by Ganesan for the bug # 4523
 ld_corp_period_to_date    DATE;          -- Added by Ganesan for the bug # 4523
 ln_corp_period_from_cnt   NUMBER;        -- Added by Ganesan for the bug # 4523
 ln_corp_period_to_cnt     NUMBER;        -- Added by Ganesan for the bug # 4523
 ln_empty_book_count       NUMBER:= 0;        -- Added by Ganesan for debuging
 ln_asset_count_corp       NUMBER;        -- Added by Ganesan for performance improvement.
 ln_asset_count_tax        NUMBER;        -- Added by Ganesan for performance improvement.

-- Changed the Cursor Queries merging the cost and depreciation Queries in Asset Cursors for defect 8826 by Ganesan
-- Cursor for getting the data other than RECLASS and TRANSFER AND RETIREMENT

CURSOR lcu_ret_add_adj(p_book  VARCHAR2,p_class VARCHAR2,p_period_from_date DATE,p_period_to_date DATE,p_period_counter_low NUMBER,p_period_counter_high NUMBER)  -- Period Informations are specific to book and passed as paramters to the cursor
IS
   SELECT asset,company,transaction,category,COST,deprn_reserve,deprn_amount,maj_cat,min_cat,sub_minor,asset_id,book,pis
   FROM
   (
   SELECT * FROM
   (
    SELECT FAB.asset_id asset
		   ,FFV.description company
                   --,FTH.transaction_header_id
		   ,FTH.transaction_type_code transaction
		   ,FC.segment1 || '/' || FC.segment2 || '/' ||FC.segment3 category
         ,nvl(sum(decode(p_transaction_type_code,
                         'ADJUSTMENT',decode(fa.debit_credit_flag,'CR',(FA.adjustment_amount*-1),FA.adjustment_amount),
                         FA.adjustment_amount)),0) COST -- Added By Ganesan for fetching the Cost and Depreciation Amounts in a Single Cursor by Ganesan for defect 8826
         ,NVL(SUM(qrslt1.deprn_reserve),0) deprn_reserve -- Added By Ganesan for fetching the Cost and Depreciation Amounts in a Single Cursor by Ganesan for defect 8826
         ,NVL(SUM(qrslt1.deprn_amount),0) deprn_amount -- Added By Ganesan for fetching the Cost and Depreciation Amounts in a Single Cursor by Ganesan for defect 8826
         ,FC.segment1 maj_Cat
		   ,FC.segment2 min_Cat
		   ,FC.segment3 sub_minor --Added by Senthil for 2315
		   ,FAB.asset_number asset_id
		   ,FB.book_type_code book
		   ,TO_CHAR (FB.date_placed_in_service,'YYYY') pis
   FROM 	fa_additions            FAB
		,fa_books                FB
      ,fa_adjustments          FA
		,fa_transaction_headers  FTH
      ,fa_distribution_history FDH
		,fa_categories           FC
		,fnd_flex_values_vl      FFV
		,gl_code_combinations    GCC
      ,(SELECT 	FDD.asset_id,
	FDD.distribution_id
        ,NVL(SUM(FDD.deprn_reserve),0) deprn_reserve
        ,NVL(SUM(FDD.deprn_amount),0) deprn_amount
	FROM	fa_deprn_detail         FDD
        WHERE FDD.book_type_code = p_book
        AND FDD.deprn_source_code  ='D'
    	AND FDD.period_counter =
        (
		SELECT MAX(FDD1.period_counter)
                FROM fa_deprn_detail FDD1
                WHERE	FDD1.book_type_code= p_book
                        AND FDD1.asset_id=FDD.asset_id
                        AND FDD1.deprn_source_code='D'
                        AND FDD1.distribution_id = FDD.distribution_id
                        AND FDD1.period_counter BETWEEN p_period_counter_low and p_period_counter_high
			)
	GROUP BY	FDD.asset_id,
	FDD.distribution_id) qrslt1
	WHERE qrslt1.asset_id=FAB.asset_id
   AND qrslt1.distribution_id  = FDH.distribution_id
   AND FAB.asset_id = FB.asset_id
	AND FAB.asset_id = FDH.asset_id
   AND FTH.transaction_header_id=FA.transaction_header_id --Added for fetching the cost and depreciation Amounts in Asset cursor by Ganesan for defect 8826
   AND FTH.book_type_code = FA.book_type_code -- Added for fetching the cost and depreciation Amounts in Asset cursor by Ganesan for defect 8826
   AND FTH.asset_id = FA.asset_id -- Added for fetching the cost and depreciation Amounts in Asset cursor by Ganesan for defect 8826
   AND FA.book_type_code=p_book -- Added for fetching the cost and depreciation Amounts in Asset cursor by Ganesan for defect 8826
   AND FTH.asset_id=FAB.asset_id -- Added for fetching the cost and depreciation Amounts in Asset cursor by Ganesan for defect 8826
   AND FA.distribution_id = FDH.distribution_id-- Added for fetching the cost and depreciation Amounts in Asset cursor by Ganesan for defect 8826
   AND FA.source_type_code = DECODE(p_transaction_type_code-- Added for fetching the cost and depreciation Amounts in Asset cursor by Ganesan for defect 8826
                                        ,'REINSTATEMENT','RETIREMENT'
                                        ,p_transaction_type_code)
   AND FA.adjustment_type ='COST'-- Added for fetching the cost and depreciation Amounts in Asset cursor by Ganesan for defect 8826
	AND FA.debit_credit_flag=DECODE(p_transaction_type_code -- Added for fetching the cost and depreciation Amounts in Asset cursor by Ganesan for defect 8826
                                        ,'REINSTATEMENT','DR'          -- This condition is added by Ganesan for handling the REINSTATEMENT transaction
                                        ,FA.debit_credit_flag)
	AND FAB.asset_id = FTH.asset_id
	AND FAB.asset_category_id = FC.category_id
	AND FB.book_type_code = FTH.book_type_code--book_cur.book_type_code
	AND FB.transaction_header_id_in = FTH.transaction_header_id
   AND FDH.code_combination_id = GCC.code_combination_id
   AND FFV.flex_value = GCC.segment1
	AND FTH.book_type_code = p_book--book_cur.book_type_code
	AND FTH.TRANSACTION_TYPE_CODE = p_transaction_type_code -- Added by Ganesan for improving performance by Ganesan for defect 8826.
   --AND to_date(FTH.date_effective,'DD-MON-RRRR') BETWEEN p_period_from_date AND p_period_to_date
   AND FTH.date_effective BETWEEN p_period_from_date AND p_period_to_date
	AND FDH.book_type_code = p_book_type_code
	AND FFV.value_category = 'OD_GL_GLOBAL_COMPANY'
   --AND FDH.date_ineffective BETWEEN p_period_from_date AND p_period_to_date
        --AND FDD1.period_counter BETWEEN p_period_counter_low and p_period_counter_high)
	AND FFV.flex_value between p_company_low and p_company_high
   GROUP BY FAB.asset_id,FFV.description,FTH.transaction_type_code
           ,FC.segment1
		     ,FC.segment2
		     ,FC.segment3
                   ,FAB.asset_number,FB.book_type_code,FB.date_placed_in_service
                   --,FTH.transaction_header_id
   )WHERE transaction=p_transaction_type_code)
   UNION
   SELECT
   0 asset
   ,NULL company
   ,p_transaction_type_code transaction
   ,' ' category
   ,0 Cost
   ,0 deprn_reserve,0 deprn_amount
   ,SUBSTR(p_category_low,0,instr(p_category_low,'.',1)-1) maj_cat
   ,SUBSTR(p_category_low,instr(p_category_low,'.',1,1)+1,instr(p_category_low,'.',1,2)-instr(p_category_low,'.',1,1)-1) min_cat
   ,SUBSTR(p_category_low,instr(p_category_low,'.',1,2)+1) sub_minor
   ,' ' asset_id
   ,p_book book
   ,TO_CHAR(sysdate,'YYYY') pis
   FROM DUAL;

-- CURSOR FOR GETTING RETIREMENT DATA
CURSOR lcu_ret(p_book  VARCHAR2,p_class VARCHAR2,p_period_from_date DATE,p_period_to_date DATE,p_period_counter_low NUMBER,p_period_counter_high NUMBER) -- Period Informations are specific to book and passed as paramters to the cursor
IS
   SELECT asset,
  company,
  TRANSACTION,
  category,
  cost,
  deprn_reserve,
  deprn_amount,
  maj_cat,
  min_cat,
  sub_minor,
  asset_id,
  book,
  pis
FROM
  (SELECT qrslt2.*
   ,NVL(qrslt1.deprn_reserve,0) deprn_reserve
   ,NVL(qrslt1.deprn_amount,0) deprn_amount
   FROM
    (SELECT * FROM (SELECT fab.asset_id asset,
       ffv.description company,
       decode(fth.transaction_type_code,    'PARTIAL RETIREMENT',    'RETIREMENT',    'FULL RETIREMENT',    'RETIREMENT',    'REINSTATEMENT',    'RETIREMENT',    fth.transaction_type_code) TRANSACTION,
       fc.segment1 || '/' || fc.segment2 || '/' || fc.segment3 category --,debit_credit_flag
    ,
       nvl(SUM(decode(fa.source_type_code,    'RETIREMENT',    decode(fa.debit_credit_flag,    'DR',  (fa.adjustment_amount * -1),    fa.adjustment_amount),    fa.adjustment_amount)),    0) cost -- Added By Ganesan for fetching the Cost and Depreciation Amounts in a Single Cursor by Ganesan for defect 8826
    ,
       fc.segment1 maj_cat,
       fc.segment2 min_cat,
       fc.segment3 sub_minor --Added by Senthil for 2315
    ,
       fab.asset_number asset_id,
       fb.book_type_code book,
       to_char(fb.date_placed_in_service,    'YYYY') pis
     FROM fa_additions fab,
       fa_books fb,
       fa_adjustments fa,
       fa_transaction_headers fth,
       fa_distribution_history fdh,
       fa_categories fc,
       fnd_flex_values_vl ffv,
       gl_code_combinations gcc

   WHERE fab.asset_id = fb.asset_id
   AND fab.asset_id = fdh.asset_id
   AND fth.transaction_header_id = fa.transaction_header_id -- Added By Ganesan for fetching the Cost and Depreciation Amounts in a Single Cursor by Ganesan for defect 8826
  AND fth.book_type_code = fa.book_type_code -- Added By Ganesan for fetching the Cost and Depreciation Amounts in a Single Cursor by Ganesan for defect 8826
  AND fth.asset_id = fa.asset_id -- Added By Ganesan for fetching the Cost and Depreciation Amounts in a Single Cursor by Ganesan for defect 8826
  AND fa.book_type_code = p_book -- Added By Ganesan for fetching the Cost and Depreciation Amounts in a Single Cursor by Ganesan for defect 8826
  AND fth.asset_id = fab.asset_id -- Added By Ganesan for fetching the Cost and Depreciation Amounts in a Single Cursor by Ganesan for defect 8826
  AND fa.distribution_id = fdh.distribution_id -- Added By Ganesan for fetching the Cost and Depreciation Amounts in a Single Cursor by Ganesan for defect 8826
  AND fa.source_type_code = p_transaction_type_code -- Added By Ganesan for fetching the Cost and Depreciation Amounts in a Single Cursor by Ganesan for defect 8826
  AND fa.adjustment_type = 'COST' -- Added By Ganesan for fetching the Cost and Depreciation Amounts in a Single Cursor by Ganesan for defect 8826
  AND fa.debit_credit_flag = decode(p_transaction_type_code -- Added By Ganesan for fetching the Cost and Depreciation Amounts in a Single Cursor by Ganesan for defect 8826
  ,    'REINSTATEMENT',    'DR' -- This condition is added by Ganesan for handling the REINSTATEMENT transaction
  ,    fa.debit_credit_flag)

   AND fab.asset_id = fth.asset_id
   AND fab.asset_category_id = fc.category_id
   AND fb.book_type_code = fth.book_type_code --book_cur.book_type_code
  AND fb.transaction_header_id_in = fth.transaction_header_id
   AND fdh.code_combination_id = gcc.code_combination_id
   AND ffv.flex_value = gcc.segment1
   AND fth.book_type_code = p_book --book_cur.book_type_code
  AND fth.transaction_type_code IN('PARTIAL RETIREMENT',    'FULL RETIREMENT',    'REINSTATEMENT') -- Added for Retirement depends on the cost and units reinstated for defect 8826 by Ganesan.
  --AND to_date(FTH.date_effective,'DD-MON-RRRR') BETWEEN p_period_from_date AND p_period_to_date
  AND FTH.date_effective BETWEEN p_period_from_date AND p_period_to_date
  AND fdh.book_type_code = p_book_type_code --AND FDH.date_ineffective BETWEEN p_period_from_date AND p_period_to_date
  AND ffv.value_category = 'OD_GL_GLOBAL_COMPANY' --AND FFV.flex_value between p_company_low and p_company_high
  GROUP BY fab.asset_id,
     ffv.description,
     decode(fth.transaction_type_code,    'PARTIAL RETIREMENT',    'RETIREMENT',    'FULL RETIREMENT',    'RETIREMENT',    'REINSTATEMENT',    'RETIREMENT',    fth.transaction_type_code),
     fc.segment1,
     fc.segment2,
     fc.segment3,
     fab.asset_number,
     fb.book_type_code,
     fb.date_placed_in_service) WHERE cost <> 0
     ) qrslt2
     , (SELECT fdd.asset_id,
         nvl(SUM(fdd.deprn_reserve),    0) deprn_reserve,
         nvl(SUM(fdd.deprn_amount),    0) deprn_amount
       FROM fa_deprn_detail fdd
       WHERE fdd.book_type_code = p_book
       AND fdd.deprn_source_code = 'D'
       AND fdd.period_counter =
        (SELECT MAX(fdd1.period_counter)
         FROM fa_deprn_detail fdd1
         WHERE fdd1.book_type_code = p_book
         AND fdd1.asset_id = fdd.asset_id
         AND fdd1.deprn_source_code = 'D'
         AND fdd1.distribution_id = fdd.distribution_id
         AND FDD1.period_counter BETWEEN p_period_counter_low and p_period_counter_high
      )
    GROUP BY fdd.asset_id)  qrslt1
WHERE qrslt1.asset_id = qrslt2.asset
AND  TRANSACTION = p_transaction_type_code)
   UNION
   SELECT
   0 asset
   ,NULL company
   ,p_transaction_type_code transaction
   ,' ' category
   ,0 Cost
   ,0 deprn_reserve,0 deprn_amount
   ,SUBSTR(p_category_low,0,instr(p_category_low,'.',1)-1) maj_cat
   ,SUBSTR(p_category_low,instr(p_category_low,'.',1,1)+1,instr(p_category_low,'.',1,2)-instr(p_category_low,'.',1,1)-1) min_cat
   ,SUBSTR(p_category_low,instr(p_category_low,'.',1,2)+1) sub_minor
   ,' ' asset_id
   ,p_book book
   ,TO_CHAR(sysdate,'YYYY') pis
   FROM DUAL;

-- Cursor For getting data pertains to RECLASS and TRANSFER transactions

CURSOR lcu_trans_reclass(p_book  VARCHAR2,p_class VARCHAR2,p_period_from_date DATE,p_period_to_date DATE,p_period_counter_low NUMBER,p_period_counter_high NUMBER) -- Period Informations are specific to book and passed as paramters to the cursor
IS
   SELECT  asset,company,transaction,category,cost,deprn_reserve,deprn_amount,maj_cat,min_cat,sub_minor,asset_id,book
           ,(SELECT TO_CHAR (FB.date_placed_in_service,   'YYYY')
             FROM fa_books FB
             WHERE FB.asset_id = asset
               AND FB.book_type_code = book
               AND rownum < 2) pis
   FROM
   (
   SELECT * FROM
   (
   SELECT FAB.asset_id asset
			 ,FFV.description company
			 ,FTH.transaction_type_code transaction
			 ,FC.segment1 || '/' || FC.segment2 || '/' || FC.segment3 category
			 ,FC.segment1 Maj_Cat
			 ,FC.segment2 Min_Cat
          ,FC.segment3 sub_minor --Added by Senthil for 2315
          ,nvl(sum(FA.adjustment_amount),0) COST -- Added By Ganesan for fetching the Cost and Depreciation Amounts in a Single Cursor by Ganesan for defect 8826
          ,NVL(SUM(qrslt1.deprn_reserve),0) deprn_reserve -- Added By Ganesan for fetching the Cost and Depreciation Amounts in a Single Cursor by Ganesan for defect 8826
          ,NVL(SUM(qrslt1.deprn_amount),0) deprn_amount -- Added By Ganesan for fetching the Cost and Depreciation Amounts in a Single Cursor by Ganesan for defect 8826
			 ,FAB.asset_number asset_id
			 ,FTH.book_type_code book
--			 ,TO_CHAR (FB.date_placed_in_service,   'YYYY') pis -- Commented by Ganesan for getting unique values
   FROM  fa_additions            FAB
			--,fa_books                FB
			,fa_transaction_headers  FTH
         ,fa_adjustments          FA -- Added By Ganesan for fetching the Cost and Depreciation Amounts in a Single Cursor by Ganesan for defect 8826
			,gl_code_combinations    GCC
			,fa_distribution_history FDH
			,fnd_flex_values_vl      FFV
			,fa_categories           FC
         ,(SELECT 	FDD.asset_id
	                  ,FDD.distribution_id
        ,NVL(SUM(FDD.deprn_reserve),0) deprn_reserve
        ,NVL(SUM(FDD.deprn_amount),0) deprn_amount
	FROM	fa_deprn_detail         FDD
        WHERE FDD.book_type_code = p_book
        AND FDD.deprn_source_code  ='D'
    	AND FDD.period_counter =
        (
		SELECT MAX(FDD1.period_counter)
                FROM fa_deprn_detail FDD1
                WHERE	FDD1.book_type_code= p_book
                        AND FDD1.asset_id=FDD.asset_id
                        AND FDD1.deprn_source_code='D'
                        AND FDD1.distribution_id = FDD.distribution_id
                        AND FDD1.period_counter BETWEEN p_period_counter_low and p_period_counter_high
			)
	GROUP BY	FDD.asset_id
	,FDD.distribution_id
   ) qrslt1
	WHERE qrslt1.asset_id=FAB.asset_id
          AND qrslt1.distribution_id  = FDH.distribution_id
          AND  /*FAB.asset_id = FB.asset_id -- Commented by Ganesan for getting unique values
	AND FB.book_type_code = FTH.book_type_code--book_cur.book_type_code
   AND */ ((FTH.transaction_header_id=FA.transaction_header_id  -- Added By Ganesan for fetching the Cost and Depreciation Amounts in a Single Cursor by Ganesan for defect 8826
   AND FA.book_type_code=FTH.book_type_code) OR (FTH.transaction_header_id=FA.transaction_header_id))
   AND FA.asset_id=FTH.asset_id -- Added By Ganesan for fetching the Cost and Depreciation Amounts in a Single Cursor by Ganesan for defect 8826
   AND FA.book_type_code=p_book -- Added By Ganesan for fetching the Cost and Depreciation Amounts in a Single Cursor by Ganesan for defect 8826
   AND FA.distribution_id = FDH.distribution_id -- Added By Ganesan for fetching the Cost and Depreciation Amounts in a Single Cursor by Ganesan for defect 8826
   AND FA.source_type_code= p_transaction_type_code -- Added By Ganesan for fetching the Cost and Depreciation Amounts in a Single Cursor by Ganesan for defect 8826
   AND FA.adjustment_type='COST' -- Added By Ganesan for fetching the Cost and Depreciation Amounts in a Single Cursor by Ganesan for defect 8826
        /*AND FA.debit_credit_flag=DECODE(p_transaction_type_code
                                        ,'REINSTATEMENT','DR'          -- This condition is added by Ganesan for handling the REINSTATEMENT transaction
                                        ,FA.debit_credit_flag)*/
   AND FA.distribution_id = FDH.distribution_id -- Added By Ganesan for fetching the Cost and Depreciation Amounts in a Single Cursor by Ganesan for defect 8826
   --AND FTH.asset_id=FAB.asset_id
	AND FDH.book_type_code = p_book_type_code
   --AND FDH.date_ineffective BETWEEN p_period_from_date AND p_period_to_date
	AND GCC.code_combination_id= FDH.code_combination_id
	AND FFV.flex_value = GCC.segment1
	AND FFV.value_category = 'OD_GL_GLOBAL_COMPANY'
	AND FDH.asset_id = FAB.asset_id
	AND FC.category_id = FAB.asset_category_id
   AND FA.debit_credit_flag = 'DR'
	AND ((FTH.transaction_header_id = FDH.transaction_header_id_in
	OR  FTH.transaction_header_id = FDH.transaction_header_id_out))
	AND FTH.asset_id = FAB.asset_id--p_asset_id
	AND FTH.book_type_code = p_book
	--AND TO_DATE(FTH.date_effective,'DD-MON-RRRR') BETWEEN p_period_from_date
	--AND p_period_to_date
	AND FTH.date_effective BETWEEN p_period_from_date AND p_period_to_date
	AND FTH.transaction_type_code IN('TRANSFER','RECLASS')
	AND p_transaction_type_code IN('TRANSFER','RECLASS')
	AND ffv.flex_value between p_company_low and p_company_high
   GROUP BY FAB.asset_id,FFV.description,FTH.transaction_type_code
         ,FC.segment1
		   ,FC.segment2
		   ,FC.segment3
         ,FAB.asset_number,FTH.book_type_code-- ,FB.date_placed_in_service commented by Ganesan for getting unique values
  ) WHERE transaction=p_transaction_type_code )
  UNION
   SELECT
   0 asset
   ,NULL company
   ,p_transaction_type_code transaction
   ,' ' category
   ,0 Cost
   ,0 deprn_reserve,0 deprn_amount
   ,SUBSTR(p_category_low,0,instr(p_category_low,'.',1)-1) maj_cat
   ,SUBSTR(p_category_low,instr(p_category_low,'.',1,1)+1,instr(p_category_low,'.',1,2)-instr(p_category_low,'.',1,1)-1) min_cat
   ,SUBSTR(p_category_low,instr(p_category_low,'.',1,2)+1) sub_minor
   ,' ' asset_id
   ,p_book book
   ,TO_CHAR(sysdate,'YYYY') pis
   FROM DUAL;

-- Cursor for getting data for active assets
CURSOR lc_active(p_book  VARCHAR2,p_class VARCHAR2,p_period_from_date DATE,p_period_to_date DATE,p_period_counter_low NUMBER,p_period_counter_high NUMBER) -- Period Informations are specific to book and passed as paramters to the cursor
IS
  SELECT asset,company,transaction,category,cost,deprn_reserve,deprn_amount,maj_cat,min_cat,sub_minor,asset_id,book,pis
FROM
(
SELECT  FAB.asset_id asset,
	FFV.description company,
        'ACTIVE' transaction,
	FC.segment1 || '/'  || FC.segment2 || '/' || FC.segment3 category,
	nvl(FB.cost,0) COST,
	nvl(SUM(qrslt1.deprn_reserve),0) deprn_reserve,
	nvl(sum(qrslt1.deprn_amount),0) deprn_amount,
	FC.segment1 maj_Cat,
	FC.segment2 min_Cat,
        FC.segment3 sub_minor, --Added by Senthil for 2315
	FAB.asset_number asset_id,
	FB.book_type_code book,
	TO_CHAR (FB.date_placed_in_service,'YYYY') pis
FROM
	fa_additions            FAB,
	fa_distribution_history FDH,
	fa_transaction_headers  FTH,
	fa_books                FB,
	gl_code_combinations    GCC,
	fnd_flex_values_vl      FFV,
	fa_categories           FC,
	(SELECT 	FDD.asset_id,
	FDD.distribution_id
        ,NVL(SUM(FDD.deprn_reserve),0) deprn_reserve
        ,NVL(SUM(FDD.deprn_amount),0) deprn_amount
	FROM	fa_deprn_detail         FDD
        WHERE FDD.book_type_code = p_book
        AND FDD.deprn_source_code  ='D'
    	AND FDD.period_counter =
        (
		SELECT MAX(FDD1.period_counter)
                FROM fa_deprn_detail FDD1
                WHERE	FDD1.book_type_code= p_book
                        AND FDD1.asset_id=FDD.asset_id
                        AND FDD1.deprn_source_code='D'
                        AND FDD1.distribution_id = FDD.distribution_id
                        AND FDD1.period_counter BETWEEN p_period_counter_low and p_period_counter_high
			)
	GROUP BY	FDD.asset_id,
	FDD.distribution_id) qrslt1
WHERE qrslt1.asset_id=FAB.asset_id
AND FDH.asset_id = FAB.asset_id
AND FAB.asset_id = FB.asset_id
AND FDH.book_type_code = p_book_type_code
AND qrslt1.distribution_id  = FDH.distribution_id
AND FTH.asset_id = FAB.asset_id
AND FTH.transaction_type_code <>'FULL RETIREMENT'
AND FTH.book_type_code = p_book
AND FTH.transaction_header_id=
			(
				SELECT MAX(FTH1.transaction_header_id)
                        	FROM fa_transaction_headers FTH1
				WHERE	FTH1.asset_id=FAB.asset_id
                                	AND FTH1.transaction_type_code NOT IN ('TRANSFER','RECLASS','TRANSFER IN','TRANSFER OUT')
                                     	AND FTH1.book_type_code=p_book
				   	AND fth1.date_effective <= p_period_to_date
			)
AND FAB.asset_id = FB.asset_id
AND FB.book_type_code = FTH.book_type_code
AND FB.transaction_header_id_in = FTH.transaction_header_id
AND GCC.code_combination_id= FDH.code_combination_id
AND FFV.flex_value = GCC.segment1
AND FC.category_id = FAB.asset_category_id
AND FFV.value_category = 'OD_GL_GLOBAL_COMPANY'
AND ffv.flex_value between p_company_low and p_company_high
GROUP BY FAB.asset_id
              ,FFV.description
              ,FTH.transaction_type_code
              ,FB.cost
              ,FC.segment1
              ,FC.segment2
	      ,FC.segment3
              ,FAB.asset_number
              ,FB.book_type_code
              ,FB.date_placed_in_service

)
WHERE transaction=p_transaction_type_code
    UNION
   SELECT
   0 asset
   ,NULL company
   ,p_transaction_type_code transaction
   ,' ' category
   ,0 Cost
   ,0 deprn_reserve,0 deprn_amount
   ,SUBSTR(p_category_low,0,instr(p_category_low,'.',1)-1) maj_cat
   ,SUBSTR(p_category_low,instr(p_category_low,'.',1,1)+1,instr(p_category_low,'.',1,2)-instr(p_category_low,'.',1,1)-1) min_cat
   ,SUBSTR(p_category_low,instr(p_category_low,'.',1,2)+1) sub_minor
   ,' ' asset_id
   ,p_book book
   ,TO_CHAR(sysdate,'YYYY') pis
   FROM DUAL;

BEGIN
   /*
     Added by Ganesan taking the corp books period_open_date and period_close_date for bug # 4523
   */
     DBMS_OUTPUT.PUT_LINE('Fetching the period opening date and counter for CORPORATE Book'); -- Added by Ganesan for debugging
     DBMS_OUTPUT.PUT_LINE('STARTED WITH TIMESTAMP: '|| SYSTIMESTAMP); -- Added by Ganesan for debugging
     BEGIN
        SELECT period_open_date,period_counter
        INTO ld_corp_period_from_date
             ,ln_corp_period_from_cnt
        FROM fa_deprn_periods
        WHERE book_type_code = p_book_type_code
          AND period_name    = p_period_from;
     EXCEPTION
     WHEN NO_DATA_FOUND THEN
         ld_corp_period_from_date := sysdate+1;
         ln_corp_period_from_cnt  := 999999999999999;
     WHEN OTHERS THEN
         ld_corp_period_from_date := sysdate+1;
         ln_corp_period_from_cnt  := 999999999999999;
     END;
     DBMS_OUTPUT.PUT_LINE('End of Fetching the period opening date and counter for CORPORATE Book');-- Added by Ganesan for debugging
     DBMS_OUTPUT.PUT_LINE('ENDED WITH TIMESTAMP: '|| SYSTIMESTAMP); -- Added by Ganesan for debugging
     DBMS_OUTPUT.PUT_LINE(CHR(10)); -- Added by Ganesan for debugging
     DBMS_OUTPUT.PUT_LINE('Fetching the period closing date and counter for CORPORATE Book'); -- Added by Ganesan for debugging
     DBMS_OUTPUT.PUT_LINE('STARTED WITH TIMESTAMP: '|| SYSTIMESTAMP); -- Added by Ganesan for debugging
     BEGIN
        SELECT NVL(period_close_date,sysdate),period_counter
        INTO ld_corp_period_to_date
             ,ln_corp_period_to_cnt
        FROM fa_deprn_periods
        WHERE book_type_code = p_book_type_code
          AND period_name    = p_period_to;
     EXCEPTION
     WHEN NO_DATA_FOUND THEN
        SELECT NVL(period_close_date,sysdate),period_counter
        INTO ld_corp_period_to_date,ln_corp_period_to_cnt
        FROM fa_deprn_periods
        WHERE book_type_code = p_book_type_code
          AND period_counter = (SELECT max(period_counter)
                                FROM fa_deprn_periods
                                WHERE book_type_code = p_book_type_code);
     WHEN OTHERS THEN
        SELECT NVL(period_close_date,sysdate),period_counter
        INTO ld_corp_period_to_date,ln_corp_period_to_cnt
        FROM fa_deprn_periods
        WHERE book_type_code = p_book_type_code
          AND period_counter = (SELECT max(period_counter)
                                FROM fa_deprn_periods
                                WHERE book_type_code = p_book_type_code);

     END;
     DBMS_OUTPUT.PUT_LINE('End of Fetching the period closing date and counter for CORPORATE Book'); -- Added by Ganesan for debugging
     DBMS_OUTPUT.PUT_LINE('ENDED WITH TIMESTAMP: '|| SYSTIMESTAMP); -- Added by Ganesan for debugging
     DBMS_OUTPUT.PUT_LINE(CHR(10)); -- Added by Ganesan for debugging
    /* End for Fix for 4523*/
	FOR book_cur IN
		(SELECT book_type_code,Book_Class
                 FROM  fa_book_controls
		 WHERE 	(book_type_code=p_book_type_code
		 OR distribution_source_book=p_book_type_code)
		 AND date_ineffective is null
		 Order by Book_class
		)
	LOOP
     /*
        The Package was passed the period Informations prevoiusly.
        But the Period Informations are specific to Book and
        so these two queries are added to fectch the Period Informations pertaining to the Book
     */
     DBMS_OUTPUT.PUT_LINE('Fetching the period opening date and counter for ANY Book'); -- Added by Ganesan for debugging
     DBMS_OUTPUT.PUT_LINE('STARTED WITH TIMESTAMP: '|| SYSTIMESTAMP); -- Added by Ganesan for debugging
     IF book_cur.book_class <> 'CORPORATE' THEN -- Added By Ganesan for executing the below section only for tax books for defect 8826 (improving perf)
        BEGIN
           SELECT period_open_date,period_counter
           INTO ld_period_from_date,ln_period_from_cnt
           FROM fa_deprn_periods
           WHERE book_type_code = book_cur.book_type_code
             AND period_name    = p_period_from;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ld_period_from_date := sysdate+1;
            ln_period_from_cnt  := 999999999999999;
        WHEN OTHERS THEN
            ld_period_from_date := sysdate+1;
            ln_period_from_cnt  := 999999999999999;
        END;
     ELSE
        ld_period_from_date := ld_corp_period_from_date; -- Added By Ganesan for executing the below section only for tax books for defect 8826 (improving perf)
        ln_period_from_cnt  := ln_corp_period_from_cnt;  -- Added By Ganesan for executing the below section only for tax books for defect 8826 (improving perf)
     END IF;
     DBMS_OUTPUT.PUT_LINE('End of Fetching the period opening date and counter for ANY Book,'); -- Added by Ganesan for debugging
     DBMS_OUTPUT.PUT_LINE('ENDED WITH TIMESTAMP: '|| SYSTIMESTAMP); -- Added by Ganesan for debugging
     DBMS_OUTPUT.PUT_LINE(CHR(10)); -- Added by Ganesan for debugging
     DBMS_OUTPUT.PUT_LINE('Fetching the period closing date and counter for ANY Book,'); -- Added by Ganesan for debugging
     DBMS_OUTPUT.PUT_LINE('STARTED WITH TIMESTAMP: '|| SYSTIMESTAMP); -- Added by Ganesan for debugging
     IF book_cur.book_class <> 'CORPORATE' THEN -- Added By Ganesan for executing the below section only for tax books for defect 8826 (improving perf)
        BEGIN
           SELECT NVL(period_close_date,sysdate),period_counter
           INTO ld_period_to_date,ln_period_to_cnt
           FROM fa_deprn_periods
           WHERE book_type_code = book_cur.book_type_code
             AND period_name    = p_period_to;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
           SELECT NVL(period_close_date,sysdate),period_counter
           INTO ld_period_to_date,ln_period_to_cnt
           FROM fa_deprn_periods
           WHERE book_type_code = book_cur.book_type_code
             AND period_counter = (SELECT max(period_counter)
                                   FROM fa_deprn_periods
                                   WHERE book_type_code = book_cur.book_type_code);
        WHEN OTHERS THEN
           SELECT NVL(period_close_date,sysdate),period_counter
           INTO ld_period_to_date,ln_period_to_cnt
           FROM fa_deprn_periods
           WHERE book_type_code = book_cur.book_type_code
             AND period_counter = (SELECT max(period_counter)
                                   FROM fa_deprn_periods
                                   WHERE book_type_code = book_cur.book_type_code);

        END;
     ELSE
        ld_period_to_date := ld_corp_period_to_date; -- Added By Ganesan for executing the below section only for tax books for defect 8826 (improving perf)
        ln_period_to_cnt  := ln_corp_period_to_cnt;  -- Added By Ganesan for executing the below section only for tax books for defect 8826 (improving perf)
     END IF;
     DBMS_OUTPUT.PUT_LINE('ld_period_from_date: ' || ld_period_from_date); -- Added by Ganesan for debugging
     DBMS_OUTPUT.PUT_LINE('ld_period_to_date: '|| ld_period_to_date); -- Added by Ganesan for debugging
     DBMS_OUTPUT.PUT_LINE('ln_period_from_cnt: '|| ln_period_from_cnt); -- Added by Ganesan for debugging
     DBMS_OUTPUT.PUT_LINE('ln_period_to_cnt: '|| ln_period_to_cnt); -- Added by Ganesan for debugging
     DBMS_OUTPUT.PUT_LINE('End of Fetching the period closing date and counter for ANY Book,'); -- Added by Ganesan for debugging
     DBMS_OUTPUT.PUT_LINE('ENDED WITH TIMESTAMP: '|| SYSTIMESTAMP); -- Added by Ganesan for debugging
     DBMS_OUTPUT.PUT_LINE(CHR(10)); -- Added by Ganesan for debugging

     --DBMS_OUTPUT.PUT_LINE('Period_count'||'From: '||ln_period_from_cnt||'To: '||ln_period_to_cnt);
     --DBMS_OUTPUT.PUT_LINE(book_cur.book_type_code || ' ' ||book_cur.book_class || ' '||P_TRANSACTION_TYPE_CODE);
     --DBMS_OUTPUT.PUT_LINE(p_company_low || ' ' || p_company_high);
      DBMS_OUTPUT.PUT_LINE('BULK Collection without Asset Cost Starts,'); -- Added by Ganesan for debugging
      DBMS_OUTPUT.PUT_LINE('STARTED WITH TIMESTAMP: '|| SYSTIMESTAMP); -- Added by Ganesan for debugging
      IF p_transaction_type_code NOT IN ('TRANSFER','RECLASS','ACTIVE')
      THEN
       --   DBMS_OUTPUT.PUT_LINE('Inside Condition');
          IF  p_transaction_type_code = 'RETIREMENT'
          THEN
         --    DBMS_OUTPUT.PUT_LINE('Inside Retirement');
             OPEN lcu_ret(book_cur.book_type_code,book_cur.book_class,ld_period_from_date,ld_period_to_date,ln_period_from_cnt,ln_period_to_cnt);
             LOOP
           --     DBMS_OUTPUT.PUT_LINE('Inside loop');
                FETCH lcu_ret
                BULK COLLECT INTO --Fix for Defect 2315
                lt_asset
                ,lt_company
                ,lt_transaction
                ,lt_category
                ,lt_amount   -- Added for defect 8826 for improving performance by Ganesan
                ,lt_deprn_reserve -- Added for defect 8826 for improving performance by Ganesan
                ,lt_deprn_amount -- Added for defect 8826 for improving performance by Ganesan
                ,lt_maj_cat
                ,lt_min_cat
                ,lt_sub_minor
                ,lt_asset_id
                ,lt_book
                ,lt_pis      ;
                EXIT WHEN lcu_ret%NOTFOUND;
              END LOOP;
             CLOSE lcu_ret;
          ELSE
             --DBMS_OUTPUT.PUT_LINE('Inside other transaction');
             OPEN lcu_ret_add_adj(book_cur.book_type_code,book_cur.book_class,ld_period_from_date,ld_period_to_date,ln_period_from_cnt,ln_period_to_cnt);
             LOOP
               -- DBMS_OUTPUT.PUT_LINE('Inside loop');
                FETCH lcu_ret_add_adj
                BULK COLLECT INTO --Fix for Defect 2315
                lt_asset
                ,lt_company
                ,lt_transaction
                ,lt_category
                ,lt_amount -- Added for defect 8826 for improving performance by Ganesan
                ,lt_deprn_reserve -- Added for defect 8826 for improving performance by Ganesan
                ,lt_deprn_amount -- Added for defect 8826 for improving performance by Ganesan
                ,lt_maj_cat
                ,lt_min_cat
                ,lt_sub_minor
                ,lt_asset_id
                ,lt_book
                ,lt_pis      ;
                EXIT WHEN lcu_ret_add_adj%NOTFOUND;
              END LOOP;
             CLOSE lcu_ret_add_adj;
          END IF;
          --DBMS_OUTPUT.PUT_LINE('Data Fetched');
          --DBMS_OUTPUT.PUT_LINE('FIRST ASSET:' || lt_asset.FIRST);
      ELSIF p_transaction_type_code IN ('TRANSFER','RECLASS')
      THEN
           IF Book_Cur.book_class = 'CORPORATE' THEN
              OPEN lcu_trans_reclass(book_cur.book_type_code,book_cur.book_class,ld_period_from_date,ld_period_to_date,ln_period_from_cnt,ln_period_to_cnt);
              LOOP
                 FETCH lcu_trans_reclass
                 BULK COLLECT INTO --Fix for Defect 2315
                 lt_asset
                 ,lt_company
                 ,lt_transaction
                 ,lt_category
                 ,lt_amount -- Added for defect 8826 for improving performance by Ganesan
                 ,lt_deprn_reserve -- Added for defect 8826 for improving performance by Ganesan
                 ,lt_deprn_amount -- Added for defect 8826 for improving performance by Ganesan
                 ,lt_maj_cat
                 ,lt_min_cat
                 ,lt_sub_minor
                 ,lt_asset_id
                 ,lt_book
                 ,lt_pis;
                 EXIT WHEN lcu_trans_reclass%NOTFOUND;
               END LOOP;
              CLOSE lcu_trans_reclass;
          ELSE
              lc_transfer_reclass_flag := 'Y';   --- In case of Transfer or reclass there wont be any change in the asset.
          END IF;
       ELSIF p_transaction_type_code = 'ACTIVE'
      THEN
          OPEN lc_active(book_cur.book_type_code,book_cur.book_class,ld_period_from_date,ld_period_to_date,ln_period_from_cnt,ln_period_to_cnt);
          LOOP
             FETCH lc_active
             BULK COLLECT INTO --Fix for Defect 2315
             lt_asset
             ,lt_company
             ,lt_transaction
             ,lt_category
             ,lt_amount -- Added for defect 8826 for improving performance by Ganesan
             ,lt_deprn_reserve -- Added for defect 8826 for improving performance by Ganesan
             ,lt_deprn_amount -- Added for defect 8826 for improving performance by Ganesan
             ,lt_maj_cat
             ,lt_min_cat
             ,lt_sub_minor
             ,lt_asset_id
             ,lt_book
             ,lt_pis;
             EXIT WHEN lc_active%NOTFOUND;
           END LOOP;
          CLOSE lc_active;
      END IF;
      DBMS_OUTPUT.PUT_LINE('No. Of times the Block has executed : '||lt_asset.count);-- Added By Ganesan for debugging
      DBMS_OUTPUT.PUT_LINE('End of BULK Collection without Asset Cost'); -- Added by Ganesan for debugging
      DBMS_OUTPUT.PUT_LINE('ENDED WITH TIMESTAMP: '|| SYSTIMESTAMP); -- Added by Ganesan for debugging
      DBMS_OUTPUT.PUT_LINE(CHR(10)); -- Added by Ganesan for debugging


      IF LT_ASSET.COUNT > 0 THEN --Fix for Defect 2315
/*        IF lc_transfer_reclass_flag <> 'Y'  -- Commented for defect 8826 since this will not have any use since these variables are already been collected.
        THEN
         lt_deprn_amount.extend(lt_asset.count);
         lt_deprn_reserve.extend(lt_asset.count);
         lt_corp_deprn.extend(lt_asset.count);
         lt_corp_reserve.extend(lt_asset.count);
         lt_amount.extend(lt_asset.count);
         lt_corp_amount.extend(lt_asset.count);
         --DBMS_OUTPUT.PUT_LINE(lt_asset.count);
         --DBMS_OUTPUT.PUT_LINE(lt_asset.first);
         --DBMS_OUTPUT.PUT_LINE(lt_asset(1));
        END IF;*/
      DBMS_OUTPUT.PUT_LINE('Fetching the Cost and depreciation amounts of the Asset,'); -- Added by Ganesan for debugging
      DBMS_OUTPUT.PUT_LINE('STARTED WITH TIMESTAMP: '|| SYSTIMESTAMP); -- Added by Ganesan for debugging
      /*
         The Below statements are commented by Ganesan for
         the Amounts are already been fetched along with Assets.
      */
/*      FOR i IN LT_ASSET.FIRST..lt_asset.LAST
      LOOP
			-- Insert for Cost


         --Fix for Defect 2315

			xxod_fin_reports_pkg.FA_DEPRN_AMOUNTS(lt_asset(i)
							       ,book_cur.book_type_code
							       ,ln_period_from_cnt--p_period_counter_low -- Changed by Ganesan Passing the Period Info
							       ,ln_period_to_cnt  --p_period_counter_high
							       ,lt_deprn_amount(i)
							       ,lt_deprn_reserve(i));

         --Fix for Defect 2315
         xxod_fin_reports_pkg.FA_DEPRN_AMOUNTS(lt_asset(i)
							       ,p_book_type_code
							       ,ln_corp_period_from_cnt--p_period_counter_low  -- Changed by Ganesan for bug# 4523 Passing the Period Info
							       ,ln_corp_period_to_cnt  --p_period_counter_high  -- Changed by Ganesan for bug# 4523
							       ,lt_corp_deprn(i)
							       ,lt_corp_reserve(i));
         --Fix for Defect 2315
         lt_amount(i) := xxod_fin_reports_pkg.fa_cost_book(
								    lt_asset(i)
								   ,book_cur.book_type_code
								   ,p_transaction_type_code
								   ,ld_period_from_date--p_period_from_date  -- Changed by Ganesan Passing the Period Info
								   ,ld_period_to_date);--p_period_to_date);
         --Fix for Defect 2315
         lt_corp_amount(i) := xxod_fin_reports_pkg.fa_cost_book(
								           lt_asset(i)
								          ,p_book_type_code
								          ,p_transaction_type_code
								          ,ld_corp_period_from_date--p_period_from_date  -- Changed by Ganesan for bug# 4523 Passing the Period Info
								          ,ld_corp_period_to_date--p_period_to_date      -- Changed by Ganesan for bug# 4523
                                  );

      END LOOP;*/
      DBMS_OUTPUT.PUT_LINE('No. Of times the Block has executed : '||lt_asset.count);-- Added By Ganesan for debugging
      DBMS_OUTPUT.PUT_LINE('End of Fetching the Cost and depreciation amounts of the Asset,'); -- Added by Ganesan for debugging
      DBMS_OUTPUT.PUT_LINE('ENDED WITH TIMESTAMP: '|| SYSTIMESTAMP); -- Added by Ganesan for debugging
      DBMS_OUTPUT.PUT_LINE(CHR(10)); -- Added by Ganesan for debugging

       -- layout type parameter added for easy exporting to excel
       DBMS_OUTPUT.PUT_LINE('inserting the Cost and depreciation amounts of the Asset into the temporary table,'); -- Added by Ganesan for debugging
       DBMS_OUTPUT.PUT_LINE('STARTED WITH TIMESTAMP: '|| SYSTIMESTAMP); -- Added by Ganesan for debugging
       IF p_layout_type = 'Cost' OR p_layout_type IS NULL THEN
          FORALL j IN lt_asset.FIRST..lt_asset.LAST

               INSERT INTO xxod_fa_cost_comp_temp
               VALUES
                  ('Cost'
                  ,1
                  ,lt_asset(j)
                  ,lt_company(j)
                  ,lt_transaction(j)
                  ,lt_category(j)
                  ,lt_asset_id(j)
                  ,book_cur.book_type_code--lt_book(j)
                  ,book_cur.book_class
                  ,lt_pis(j)
                  ,ROUND(lt_amount(j),2)                 -- Rounded for showing the correct value                 --asset_cur.amount
                  ,DECODE(book_cur.book_class,'CORPORATE',ROUND(lt_amount(j),2),0) -- Commented By Ganesan Since the MERGER Statement would populate it ,ROUND(lt_corp_amount(j),2)            -- Rounded for showing the correct value                 --asset_cur.corp_amount
                  ,lt_maj_cat(j)
                  ,lt_min_cat(j)
                  ,lt_sub_minor(j)
                  );
          END IF;
            -- Insert for deprn_amount

          -- layout type parameter added for easy exporting to excel
          IF p_layout_type = 'Depreciation Amount' OR p_layout_type IS NULL THEN
             FORALL k IN lt_asset.FIRST..lt_asset.LAST
               INSERT INTO xxod_fa_cost_comp_temp
               VALUES
                  ('Depreciation Amount'
                  ,2
                  ,lt_asset(k)
                  ,lt_company(k)
                  ,lt_transaction(k)
                  ,lt_category(k)
                  ,lt_asset_id(k)
                  ,book_cur.book_type_code--lt_book(k)
                  ,book_cur.book_class
                  ,lt_pis(k)
                  ,ROUND(lt_deprn_amount(k),2)           -- Rounded for showing the correct value
                  ,DECODE(book_cur.book_class,'CORPORATE',ROUND(lt_deprn_amount(k),2),0)-- Commented By Ganesan Since the MERGER Statement would populate it
                  ,lt_maj_cat(k)
                  ,lt_min_cat(k)
                  ,lt_sub_minor(k)
                  );
            END IF;
            --Insert for Accumulated Deprn

           -- layout type parameter added for easy exporting to excel
           IF p_layout_type = 'Accumulated Depreciation' OR p_layout_type IS NULL THEN
             FORALL m IN lt_asset.FIRST..lt_asset.LAST
               INSERT INTO xxod_fa_cost_comp_temp
               VALUES
                  ('Accumulated Depreciation'
                  ,3
                  ,lt_asset(m)
                  ,lt_company(m)
                  ,lt_transaction(m)
                  ,lt_category(m)
                  ,lt_asset_id(m)
                  ,book_cur.book_type_code--lt_book(m)
                  ,book_cur.book_class
                  ,lt_pis(m)--,lt_amount(m),0
                  ,ROUND(lt_deprn_reserve(m),2)        -- Rounded for showing the correct value
                  ,DECODE(book_cur.book_class,'CORPORATE',ROUND(lt_deprn_reserve(m),2),0)-- Commented By Ganesan Since the MERGER Statement would populate it
                  --,ROUND(lt_corp_reserve(m),2)         -- Rounded for showing the correct value
                  ,lt_maj_cat(m)
                  ,lt_min_cat(m)
                  ,lt_sub_minor(m)
                  );
            END IF;
            DBMS_OUTPUT.PUT_LINE('No. Of times the Block has executed : '||lt_asset.count);-- Added By Ganesan for debugging
            DBMS_OUTPUT.PUT_LINE('End of inserting the Cost and depreciation amounts of the Asset into the temporary table,'); -- Added by Ganesan for debugging
            DBMS_OUTPUT.PUT_LINE('ENDED WITH TIMESTAMP: '|| SYSTIMESTAMP); -- Added by Ganesan for debugging
            DBMS_OUTPUT.PUT_LINE(CHR(10)); -- Added by Ganesan for debugging
	   END IF;
      /* Added for getting the corp amount by Ganesan.*/
      BEGIN
        DBMS_OUTPUT.PUT_LINE('Inside the MERGE');
        IF p_layout_type = 'Cost' OR p_layout_type IS NULL THEN
           MERGE INTO xxod_fa_cost_comp_temp xfcct
           USING (
           SELECT *
           FROM xxod_fa_cost_comp_temp
           WHERE book_class = 'CORPORATE'
             AND layout_type = 'Cost') xfcct_corp
           ON (xfcct.asset = xfcct_corp.asset
           --AND xfcct.book_class = 'TAX'
           AND xfcct.layout_type = 'Cost'
           AND xfcct.book = BOOK_CUR.BOOK_TYPE_CODE)
           WHEN MATCHED THEN
              UPDATE SET xfcct.corp_amount = xfcct_corp.amount
           WHEN NOT MATCHED THEN
              INSERT VALUES(xfcct_corp.LAYOUT_TYPE
                            ,xfcct_corp.LAYOUT_SORT
                            ,xfcct_corp.ASSET
                            ,xfcct_corp.COMPANY
                            ,xfcct_corp.TRANSACTION
                            ,xfcct_corp.CATEGORY
                            ,xfcct_corp.ASSET_ID
                            ,BOOK_CUR.BOOK_TYPE_CODE
                            ,book_cur.book_class
                            ,xfcct_corp.PIS
                            ,0 --AMOUNT
                            ,xfcct_corp.amount
                            ,xfcct_corp.MAJ_CAT
                            ,xfcct_corp.MIN_CAT
                            ,xfcct_corp.SUB_MINOR);
        END IF;
        IF p_layout_type = 'Depreciation Amount' OR p_layout_type IS NULL THEN
           MERGE INTO xxod_fa_cost_comp_temp xfcct
           USING (
           SELECT *
           FROM xxod_fa_cost_comp_temp
           WHERE book_class = 'CORPORATE'
             AND layout_type = 'Depreciation Amount') xfcct_corp
           ON (xfcct.asset = xfcct_corp.asset
           --AND xfcct.book_class = 'TAX'
           AND xfcct.layout_type = 'Depreciation Amount'
           AND xfcct.book = BOOK_CUR.BOOK_TYPE_CODE)
           WHEN MATCHED THEN
              UPDATE SET xfcct.corp_amount = xfcct_corp.amount
           WHEN NOT MATCHED THEN
              INSERT VALUES(xfcct_corp.LAYOUT_TYPE
                            ,xfcct_corp.LAYOUT_SORT
                            ,xfcct_corp.ASSET
                            ,xfcct_corp.COMPANY
                            ,xfcct_corp.TRANSACTION
                            ,xfcct_corp.CATEGORY
                            ,xfcct_corp.ASSET_ID
                            ,BOOK_CUR.BOOK_TYPE_CODE
                            ,book_cur.book_class
                            ,xfcct_corp.PIS
                            ,0 --AMOUNT
                            ,xfcct_corp.amount
                            ,xfcct_corp.MAJ_CAT
                            ,xfcct_corp.MIN_CAT
                            ,xfcct_corp.SUB_MINOR);
        END IF;
        IF p_layout_type = 'Accumulated Depreciation' OR p_layout_type IS NULL THEN
           MERGE INTO xxod_fa_cost_comp_temp xfcct
           USING (
           SELECT *
           FROM xxod_fa_cost_comp_temp
           WHERE book_class = 'CORPORATE'
             AND layout_type = 'Accumulated Depreciation') xfcct_corp
           ON (xfcct.asset = xfcct_corp.asset
           --AND xfcct.book_class = 'TAX'
           AND xfcct.layout_type = 'Accumulated Depreciation'
           AND xfcct.book = BOOK_CUR.BOOK_TYPE_CODE)
           WHEN MATCHED THEN
              UPDATE SET xfcct.corp_amount = xfcct_corp.amount
           WHEN NOT MATCHED THEN
              INSERT VALUES(xfcct_corp.LAYOUT_TYPE
                            ,xfcct_corp.LAYOUT_SORT
                            ,xfcct_corp.ASSET
                            ,xfcct_corp.COMPANY
                            ,xfcct_corp.TRANSACTION
                            ,xfcct_corp.CATEGORY
                            ,xfcct_corp.ASSET_ID
                            ,BOOK_CUR.BOOK_TYPE_CODE
                            ,book_cur.book_class
                            ,xfcct_corp.PIS
                            ,0 --AMOUNT
                            ,xfcct_corp.amount
                            ,xfcct_corp.MAJ_CAT
                            ,xfcct_corp.MIN_CAT
                            ,xfcct_corp.SUB_MINOR);
        END IF;
      EXCEPTION
      WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE('Exception raised while Merging data into temporary table' || SQLERRM);
      END;

	END LOOP;

   /*
      This block is been added for making sure
      the difference is there for the assets
      which are not moved to the corresponding TAX books, by inserting the corp_book_amount for those assets and tax book amount as 0
   */
   /*
      This block is for making sure that not all Tax books enter the below block for defect  8826.
   */
/*

   IF p_transaction_type_code NOT IN ('TRANSFER','RECLASS')
   THEN
         -- Getting the count of assets in CORP Book added for improving performance as per defect 8826.
      SELECT COUNT(asset_id)
      INTO ln_asset_count_corp
      FROM xxod_fa_cost_comp_temp
      WHERE book_class = 'CORPORATE';
      DBMS_OUTPUT.PUT_LINE('inserting the Cost and depreciation amounts as 0 for all Assets into the temporary table,'); -- Added by Ganesan for debugging
      DBMS_OUTPUT.PUT_LINE('STARTED WITH TIMESTAMP: '|| SYSTIMESTAMP); -- Added by Ganesan for debugging
      --FOR BOOK_CUR2 IN (SELECT book_type_code FROM fa_book_controls WHERE distribution_source_book= p_book_type_code AND book_class='TAX') Commented by Ganesan for performance improvement for defect  8826
      FOR BOOK_CUR2 IN (SELECT COUNT(asset_id),book BOOK_TYPE_CODE FROM xxod_fa_cost_comp_temp WHERE book_class = 'TAX' GROUP BY book HAVING COUNT(asset_id) <> ln_asset_count_corp ) -- Added for improving the performance for defect  8826
      LOOP
         INSERT INTO xxod_fa_cost_comp_temp
              SELECT LAYOUT_TYPE
                  ,LAYOUT_SORT
                  ,ASSET
                  ,COMPANY
                  ,TRANSACTION
                  ,CATEGORY
                  ,ASSET_ID
                  ,BOOK_CUR2.BOOK_TYPE_CODE
                  ,'TAX' -- BOOK_CLASS
                  ,PIS
                  ,0 --AMOUNT
                  ,CORP_AMOUNT
                  ,MAJ_CAT
                  ,MIN_CAT
                      ,SUB_MINOR
             FROM xxod_fa_cost_comp_temp XFCCT
             WHERE XFCCT.book=P_BOOK_TYPE_CODE
             AND XFCCT.LAYOUT_TYPE=Nvl(p_layout_type,XFCCT.LAYOUT_TYPE)
             AND NOT EXISTS(       -- Modified from NOT IN by Ganesan for defect 8826
                  SELECT asset_id
                  FROM xxod_fa_cost_comp_temp
                  WHERE book =BOOK_CUR2.BOOK_TYPE_CODE
                    AND  asset_id = XFCCT.asset_id
                    AND LAYOUT_TYPE=Nvl(p_layout_type,LAYOUT_TYPE)) ;
          DBMS_OUTPUT.PUT_LINE('Inserting Records');
      END LOOP;
      DBMS_OUTPUT.PUT_LINE('End of insertion of Cost and depreciation amounts as 0 for all Assets into the temporary table,'); -- Added by Ganesan for debugging
      DBMS_OUTPUT.PUT_LINE('ENDED WITH TIMESTAMP: '|| SYSTIMESTAMP); -- Added by Ganesan for debugging
      DBMS_OUTPUT.PUT_LINE(CHR(10)); -- Added by Ganesan for debugging
   END IF;*/
END POPULATE_ASSET_DETAILS;
END XXOD_TRANS_COMP_PKG;
/
sho err