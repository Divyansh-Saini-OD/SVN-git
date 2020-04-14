create or replace PACKAGE BODY xx_ce_store_os_cc_pkg
AS
-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- |                            Providge Consulting                                  |
-- +=================================================================================+
-- | Name       : XX_CE_STORE_OS_CC_PKG.pkb                                          |
-- | Description: OD Cash Management Store Over/Short and Sweep Extension            |
-- |                                                                                 |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version  Date         Authors            Remarks                                 |
-- |=======  ===========  ===============    ============================            |
-- |1.0      23-JUL-2007  Terry Banks        Initial version                         |
-- |1.1      21-AUG-2007  Terry Banks        Added 'PTY' and 'MIS' GL Processing     |
-- |1.2      19-SEP-2007  Terry Banks        Added summary GL Creation Reporting     |
-- |1.3      03-OCT-2007  Terry Banks        Corrected trans code 575 processing     |
-- |1.4      13-MAR-2008  Deepak Gowda       Defect 5316 - Over Short amount debits  |
-- |                                         and credits are switched around.Updated |
-- |                                         to use absolute amounts. Corrected Log  |
-- |1.5      13-MAR-2008  Deepak Gowda       Defect 5249 - Pass the Statement Line   |
-- |                                         amount to xx_ce_999_interface.          |
-- |1.6      16-MAR-2008  Deepak Gowda       Defect 5438 - Pass matched amount,      |
-- |                                         deposits matched/expenses_cleared flags |
-- |1.7      31-Mar-2008  Deepak Gowda       Defect 5883 - Select as change trx when |
-- |                                         trx_code is not 366,575,666,629 and     |
-- |                                         invoice text starts with '33'-Account   |
-- |                                         exactly as 366.                         |
-- |1.8      08-Apr-2008  Sarat Uppalapati   Defect 5942 - Added description in each |
-- |                                         of the journal entry Dr and Cr          |
-- |                                         actions description                     |
-- |1.9      28-Apr-2008  Deepak Gowda       Defect 5956 - Modified error handling   |
-- |                                         to trap errors and process them locally.|
-- |                                         Updated to use GL_PSFIN_COST_CENTER and |
-- |                                         GL_PSFIN_COST_CENTER translations for   |
-- |                                         legacy to EBiz translations for dept    |
-- |                                         and account.                            |
-- |2.0      14-May-2008  Deepak Gowda       Defect 5956 - Dept from POS is 3 digits |
-- |                                          whereas translation is 4 digits with   |
-- |                                          a leading zero.                        |
-- |2.1      15-May-2008  Deepak Gowda      Updated log message to display translate |
-- |                                         API errors.  Added output and logging   |
-- |                                         for change fund processing.             |
-- |2.2      10-Jun-2008 Deepak Gowda       Defect 7886-Added handling for user named|
-- |                                         exception. Performance fixes.           |
-- |2.3      07-Jul-2008 Deepak Gowda       CR423- Do Not process Trxcodes366/629/666|
-- |2.4      09-Aug-2008 Deepak Gowda       Defect 10511 - Use Sysdate for Accounting|
-- |                                        date instead of Sales date.              |
-- |2.5      09-Aug-2008 Deepak Gowda       Defect 10761 - Revise calculations of    |
-- |                                        Store Over/Short calculations to include |
-- |                                        cash and check receipts less Debit card  |
-- |                                        cash backs                               |
-- |2.6      10-Sep-2008 Deepak Gowda       Defect 11020 - Setup to treat 577 TrxCode|
-- |                                        same as 575.  Revised to use lookup      |
-- |                                        instead of hard coding the values        |
-- |2.7      15-Sep-2008 Deepak Gowda       Defect 11163 - Restrict processing to    |
-- |                                        locations that belong to the operating   |
-- |                                        unit where the process is run            |
-- |2.8      20-NOV-2008 Pradeep Krishnan   Defect 12401 - Updated the code to       |
-- |                                        include the store location of the        |
-- |                                        HR Type STORESTDT.                       |
-- |2.9      27-MAR-2009 Rani Asaithambi                     CR 559A                 |
-- |                                        Created a procedure- NULL_SER_NUM_REPLACE|
-- |                                        for CR 559A, where this procedure can be |
-- |                                        commented while implementing CR 559.     |
-- |                                        This procedure updates the table -       |
-- |                                        xx_ce_store_bank_deposits, serial_num col|
-- |                                        with X001 to X999 if the serial_num col  |
-- |                                        is NULL. When this update reaches X999 we|
-- |                                        again start updating from X001 and this  |
-- |                                        cycle continues.                         |
-- |                                        Also commented the Change Fund and Cash  |
-- |                                        Concentration process. Removed ZBA Codes.|
-- |3.0      06-May-2009 Rani Asaithambi    Defect 14569-  Changed the procedure     |
-- |                                        NULL_SER_NUM_REPLACE to update the table |
-- |                                        xx_ce_store_bank_deposits, serial_num col|
-- |                                        with X001 to X999 if the serial_num col  |
-- |                                        is NULL, 0, 00, 000 and 0000.            |
-- |3.1      08-May-2009 Rani Asaithambi    Hardcoded the Cost Center value as 43002 |
-- |                                        for PTY and NON-MIS deposits.            |
-- |3.2      13-May-2009 Pradeep Krishnan   Defect 14766 - Updated the code to       |
-- |                                        include the store location of the        |
-- |                                        Type STORESTMG.                          |
-- |3.3      20-May-2009 Pradeep Krishnan   Defect 15329 - Updated the code to       |
-- |                                        fetch only the statement lines for which |
-- |                                        the transaction code's trans source is   |
-- |                                        setup as 'Open Interface'                |
-- |3.4      20-Jul-2009 Pradeep Krishnan   Updated the code for the defect 833      |
-- |                                        to look for 30 days of statement from    |
-- |                                        the sales date for                       |
-- |3.5      24-Dec-2009 Anitha Devarajulu  Fix for CR 559                           |
-- |3.6      26-May-2010 Cindhu Nagarajan   Added a query to check open periods for  |
-- |                                        Defect # 5189                            |
-- |3.7      26-Aug-2010 Ganga Devi R       Made changes to avoid double matching for|
-- |                                        defect#7656                              |
-- |3.8      22-Nov-2011 Rajeshkumar M R    Made changes to avoid double matching for|
-- |                                        defect#11531                             |
-- |3.9      8-Jul-2013 Aradhna Sharma      E1318-Made changes for R12 retrofit      |
-- |4.0      16-Sep-2013 Aradhna Sharma     E1318-Made changes for R12 retrofit      |
-- |                                        Adding trx_code in ce_stamements_lines   |
-- |4.1      12-Dec-2013 Aradhna Sharma     Added for R12 retrofit defect#26545      |
-- |4.2      22-Oct-2014 Shereen Colaco     Including account type lookup'DEPOSIT'#  |
-- |                                        for defect# 32125			     |
-- |4.3      29-OCT-2015 Avinash            R12.2 Compliance Changes                 |
-- |4.4      02-Nov-2015 Rakesh Polepalli   Modified for the defect# 36086		     |
-- |4.5      27-Mar-2017 Pritidarshini Jena	Modified for the Defect# 41450           |
-- |4.6      30-May-2017 Rohit Nanda	    Modified for the Defect# 42107           |
-- |5.1      30-Mar-2020 Amit Kumar	    	E1319 changes to not consider Wells Fargo|
-- |											Records in main cursors.		     |
-- +=================================================================================+
-- |Name        :                                                                    |
-- | Description : This procedure will be used to process the                        |
-- |               OD Cash Management Store Deposit Over/Short                       |
-- |               and Cash Concentration extention.                                 |
-- |                                                                                 |
-- | Parameters  : None                                                              |
-- |                                                                                 |
-- |                                                                                 |
-- | Returns     : x_errbuf                                                          |
-- |               x_retcode                                                         |
-- |                                                                                 |
-- +=================================================================================+
--
   gc_line   VARCHAR2 (80)
              := '------------------------------------------------------------';
 -- Added Translation Name for R 1.2 CR 559 Fix
   gc_trans_name   VARCHAR2 (50)  := 'XX_CM_E1318_STORE_OS_CC';

   FUNCTION pf_derive_lob (pfv_location IN VARCHAR2, pfv_cost_center IN VARCHAR2)
      RETURN VARCHAR2
   IS
      pfv_lob             gl_code_combinations.segment7%TYPE;
      pfv_error_message   VARCHAR2 (200);
   BEGIN
      xx_gl_translate_utl_pkg.derive_lob_from_costctr_loc (pfv_location
                                                         , pfv_cost_center
                                                         , pfv_lob
                                                         , pfv_error_message
                                                          );

      IF pfv_error_message IS NOT NULL
      THEN
         pfv_lob := -1;
      END IF;

      RETURN (NVL (pfv_lob, -1));
   END;

   PROCEDURE store_os_cc_main (
      x_errbuf    OUT NOCOPY   VARCHAR2
    , x_retcode   OUT NOCOPY   NUMBER
   )
   AS
      n1                             NUMBER;
      gn_set_of_bks_id               NUMBER
                                      := fnd_profile.VALUE ('GL_SET_OF_BKS_ID');
      gn_org_id                      NUMBER     := fnd_profile.VALUE ('ORG_ID');
      lc_aba_key                     VARCHAR2 (006);
      ln_bank_account_id             NUMBER;
     --- lc_bank_account_num            ap_bank_accounts_all.bank_account_num%TYPE;    ----Commented for R12 retrofit by Aradhna Sharma on 8-July-2013
       lc_bank_account_num            ce_bank_accounts.bank_account_num%TYPE;      ----added for R12 retrofit by Aradhna Sharma on 8-July-2013
      ln_ccid                        NUMBER;
      gn_coa_id                      NUMBER;
      lc_csl_bank_account_text       ce_statement_lines.bank_account_text%TYPE;
      lc_csl_bank_trx_number         ce_statement_lines.bank_trx_number%TYPE;
      lc_csl_customer_text           ce_statement_lines.customer_text%TYPE;
      lc_csl_invoice_text            ce_statement_lines.invoice_text%TYPE;
      ln_csl_deposit_amt             ce_statement_lines.amount%TYPE;
      ln_csl_statement_line_id       ce_statement_lines.statement_line_id%TYPE;
      ln_csl_statement_header_id     ce_statement_lines.statement_header_id%TYPE;
      ln_csl_trx_code_id             ce_statement_lines.trx_code_id%TYPE;
      ln_csl_trx_code                ce_statement_lines.trx_code%TYPE;                     ----Added for R12 retrofit by Aradhna Sharma on 19-Sep-2013 for Defect #25480
      ln_csl_trx_code_001_id         NUMBER;
      ln_csl_trx_code_001            ce_statement_lines.trx_code%TYPE;                      ----Added for R12 retrofit by Aradhna Sharma on 19-Sep-2013 for Defect #25480
      ld_csl_trx_date                ce_statement_lines.trx_date%TYPE;
    ----------  lc_currency_code               ap_bank_accounts_all.currency_code%TYPE;   ----Commented for R12 retrofit by Aradhna Sharma on 8-July-2013
      lc_currency_code               ce_bank_accounts.currency_code%TYPE;                   ----added for R12 retrofit by Aradhna Sharma on 8-July-2013
      ln_deposit_bank_difference     NUMBER;
      lc_error_loc                   VARCHAR2 (60);
      lc_error_msg                   VARCHAR2 (2500);
      le_exception_999               EXCEPTION;
      le_exception_bad_store         EXCEPTION;
      le_exception_gl_call           EXCEPTION;
      le_exception_store_accounts    EXCEPTION;
      le_exception_store_receipts    EXCEPTION;
      le_exception_trx_code          EXCEPTION;
      le_exception_no_match          EXCEPTION;
      le_exception_translate         EXCEPTION;
      ln_group_id                    NUMBER;
      lc_print_line                  VARCHAR2 (200);
      ln_loc_id                      NUMBER;
      lc_loc_4                       VARCHAR2 (4);
      ln_login_id                    NUMBER              := fnd_global.login_id;
      lc_oracle_error_msg            VARCHAR2 (1000);
      ln_org_id                      NUMBER;
      lc_output_msg                  VARCHAR2 (255);
      ln_request_id                  NUMBER       := fnd_global.conc_request_id;
      ln_retcode                     NUMBER;
      ld_sales_date                  DATE;
      lc_seg_co                      gl_code_combinations.segment1%TYPE;
      lc_seg_cost                    gl_code_combinations.segment2%TYPE;
      lc_seg_acct                    gl_code_combinations.segment3%TYPE;
      lc_seg_loc                     gl_code_combinations.segment4%TYPE;
      lc_seg_ic                      gl_code_combinations.segment5%TYPE;
      lc_seg_lob                     gl_code_combinations.segment6%TYPE;
      lc_seg_fut                     gl_code_combinations.segment7%TYPE;
      ln_seq_999                     NUMBER;
      lc_serial_loc                  VARCHAR2 (8);
      lc_serial_num                  xx_ce_store_bank_deposits.serial_num%TYPE;
     --- ln_set_of_books_id             ap_bank_accounts_all.set_of_books_id%TYPE;  ----Commented for R12 retrofit by Aradhna Sharma on 8-July-2013
      ln_set_of_books_id             gl_ledgers.ledger_id%TYPE;   ----added for R12 retrofit by Aradhna Sharma on 8-July-2013
      lc_status_cd                   xx_ce_store_bank_deposits.status_cd%TYPE;
      ln_store_amount                NUMBER;
      lc_store_cash_account          gl_code_combinations.segment3%TYPE;
      lc_store_cash_clearing         gl_code_combinations.segment3%TYPE;
      lc_store_seg_cost              gl_code_combinations.segment2%TYPE;
      ln_store_deposit_seq_nbr       NUMBER;
      ln_store_receipts_difference   NUMBER;
      ln_sum_ar_receipts             NUMBER;
      ln_sum_ar_refunds              NUMBER;
      ln_sum_db_card_cash_backs      NUMBER;
      ln_sum_cash_deposits           NUMBER;
      ln_sum_check_deposits          NUMBER;
      ln_sum_misc_deposits           NUMBER;
      ln_sum_other_deposits          NUMBER;
      ln_sum_petty                   NUMBER;
      lc_translate_error             VARCHAR2 (400);
      lc_translate_seg_acct          gl_code_combinations.segment3%TYPE;
      lc_translate_seg_cost          gl_code_combinations.segment2%TYPE;
      ln_user_id                     NUMBER               := fnd_global.user_id;
      ln_error                       NUMBER                                := 2;
      ln_warning                     NUMBER                                := 1;
      ln_normal                      NUMBER                                := 0;
      lc_je_line_dsc                 VARCHAR2 (240);            -- Defect 5942.
      lc_ch_dep_savepoint            VARCHAR2 (100);
      lc_sdb_savepoint               VARCHAR2 (200);
      lc_st_dep_savepoint            VARCHAR2 (200);
      ln_rec_count                   NUMBER                                := 0;
      ln_det_count                   NUMBER                                := 0;
      lc_output_line                 VARCHAR2 (2000);

/*****************R 1.2 CR 559 Fix****************Starts****************/
  -- Added Local Variables
      lc_trans_seg_cost              gl_code_combinations.segment2%TYPE;
      lc_trans_seg_cost_dr           gl_code_combinations.segment2%TYPE;
      lc_trans_seg_cost_mis          gl_code_combinations.segment2%TYPE;
      lc_trans_seg_cost_mis_dr       gl_code_combinations.segment2%TYPE;
      lc_trans_seg_acct              gl_code_combinations.segment3%TYPE;
      lc_trans_seg_acct_dr           gl_code_combinations.segment3%TYPE;
      lc_trans_seg_acct_mis_dr       gl_code_combinations.segment3%TYPE;
      lc_trans_seg_loc               gl_code_combinations.segment4%TYPE;
      lc_trans_seg_loc_mis_dr        gl_code_combinations.segment4%TYPE;
      lb_flag                        BOOLEAN DEFAULT FALSE;
      lc_flag                        VARCHAR2(1) DEFAULT 'N';
      ln_sum_cash_check_deposits     NUMBER;
      ld_bank_statement_date         ce_statement_headers.statement_date%TYPE;
      lc_match_type                  VARCHAR2(20);
      ln_appl_id                     fnd_application.application_id%TYPE;
      ln_days                        NUMBER;
/*****************R 1.2 CR 559 Fix****************Ends****************/

/****************************** R1.5 Cursur changes to exclude Wells Fargo Records Starts  *****************************/
/*      CURSOR c_store_deposit
      IS
         SELECT DISTINCT sales_date, loc_id, status_cd
                    FROM xx_ce_store_bank_deposits xcs
/*****************R 1.2 CR 559 Fix****************Starts****************/
 -- Commented Hard Coded Values and Added Translation
             --      WHERE NVL (status_cd, '~') NOT IN ('B', 'S')
 /*                  WHERE NVL (status_cd, '~') NOT IN (
                                                 SELECT XFTV.TARGET_value1
                                                   FROM xx_fin_translatedefinition XFTD
                                                        ,xx_fin_translatevalues XFTV
                                                  WHERE XFTD.translate_id = XFTV.translate_id
                                                    AND XFTD.translation_name = gc_trans_name
                                                    AND XFTV.source_value1 = 'EX_STATUS_CODE'
                                                    AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                                                    AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                                                    AND XFTV.enabled_flag = 'Y'
                                                    AND XFTD.enabled_flag = 'Y')
/*****************R 1.2 CR 559 Fix****************Ends****************/
  /*                   AND EXISTS (
                           SELECT 1
                             FROM hr_all_organization_units hro
                            WHERE hro.attribute1 = xcs.loc_id
                              AND xx_fin_country_defaults_pkg.f_org_id
                                                                 (hro.attribute5) =
                                                                       gn_org_id
                                --AND hro.TYPE = 'STORESTRG')
                --              AND hro.TYPE IN ('STORESTDT','STORESTRG')) -- Commented for defect 14677
/*****************R 1.2 CR 559 Fix****************Starts****************/
 -- Commented Hard Coded Values and Added Translation
                                      --        AND hro.TYPE IN ('STORESTDT','STORESTRG','STORESTMG')) -- Added for defect 14677
 /*                                             AND hro.TYPE IN (
                                                 SELECT XFTV.TARGET_value1
                                                   FROM xx_fin_translatedefinition XFTD
                                                        ,xx_fin_translatevalues XFTV
                                                  WHERE XFTD.translate_id = XFTV.translate_id
                                                    AND XFTD.translation_name = gc_trans_name
                                                    AND XFTV.source_value1 = 'ORG_TYPE'
                                                    AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                                                    AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                                                    AND XFTV.enabled_flag = 'Y'
                                                    AND XFTD.enabled_flag = 'Y'))
/*****************R 1.2 CR 559 Fix****************Ends****************/
 /*               ORDER BY 1, 2;

 /*     CURSOR c_store_deposit_bank
      IS
         SELECT DISTINCT sales_date, loc_id, status_cd, serial_num, amount
                       , seq_nbr, deposit_type
                    FROM xx_ce_store_bank_deposits xcs
/*****************R 1.2 CR 559 Fix****************Starts****************/
 -- Commented Hard Coded Values and Added Translation
             --      WHERE NVL (status_cd, '~') = 'S'
 /*                  WHERE NVL (status_cd, '~') = (
                                         SELECT XFTV.TARGET_value1
                                           FROM xx_fin_translatedefinition XFTD
                                                ,xx_fin_translatevalues XFTV
                                          WHERE XFTD.translate_id = XFTV.translate_id
                                            AND XFTD.translation_name = gc_trans_name
                                            AND XFTV.source_value1 = 'IN_STATUS_CODE'
                                            AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                                            AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                                            AND XFTV.enabled_flag = 'Y'
                                            AND XFTD.enabled_flag = 'Y')
/*****************R 1.2 CR 559 Fix****************Ends****************/
                     -- <> 'B'
                     --  Don't do if store/AR .
                     --  failed because setup of
                     --  store is probably bad
 /*                    AND deposit_type NOT IN ('PTY','CHG')
 /*                    AND EXISTS (
                           SELECT 1
                             FROM hr_all_organization_units hro
                            WHERE hro.attribute1 = xcs.loc_id
                              AND xx_fin_country_defaults_pkg.f_org_id
                                                                 (hro.attribute5) =
                                                                       gn_org_id
                                  --AND hro.TYPE = 'STORESTRG')
                   --           AND hro.TYPE IN ('STORESTDT','STORESTRG')) -- Commented for defect 14677
/*****************R 1.2 CR 559 Fix****************Starts****************/
 -- Commented Hard Coded Values and Added Translation
  /*                                       --     AND hro.TYPE IN ('STORESTDT','STORESTRG','STORESTMG'))  -- Added for defect 14677
                                            AND hro.TYPE IN (
                                                 SELECT XFTV.TARGET_value1
                                                   FROM xx_fin_translatedefinition XFTD
                                                        ,xx_fin_translatevalues XFTV
                                                  WHERE XFTD.translate_id = XFTV.translate_id
                                                    AND XFTD.translation_name = gc_trans_name
                                                    AND XFTV.source_value1 = 'ORG_TYPE'
                                                    AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                                                    AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                                                    AND XFTV.enabled_flag = 'Y'
                                                    AND XFTD.enabled_flag = 'Y'))
/*****************R 1.2 CR 559 Fix****************Ends****************/
 /*              ORDER BY 1, 2;
*/

		CURSOR c_store_deposit
		IS
		   SELECT sales_Date,
			  loc_id,
			  status_cd,
			  serial_num,
			  amount,
			  seq_nbr,
			  deposit_type,
			  location_id
			FROM
			  (SELECT /*+ INDEX(xcs,XX_CE_STORE_BANK_DEPOSITS_F3) */ DISTINCT sales_date,
				loc_id,
				status_cd,
				serial_num,
				amount ,
				seq_nbr,
				deposit_type,
				LPAD (TO_CHAR (xcs.loc_id), 6, '0') location_id
			  FROM xx_ce_store_bank_deposits xcs
			  WHERE status_cd ='N'
			  AND  EXISTS
					  (SELECT 1
					  FROM hr_all_organization_units hro
					  WHERE hro.attribute1                                      = to_char(xcs.loc_id)
					  AND xx_fin_country_defaults_pkg.f_org_id (hro.attribute5) = gn_org_id
					  AND hro.TYPE                                             IN
						(SELECT XFTV.TARGET_value1
						FROM xx_fin_translatedefinition XFTD ,
						  xx_fin_translatevalues XFTV
						WHERE XFTD.translate_id   = XFTV.translate_id
						AND XFTD.translation_name = gc_trans_name
						AND XFTV.source_value1    = 'ORG_TYPE'
						AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
						AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
						AND XFTV.enabled_flag = 'Y'
						AND XFTD.enabled_flag = 'Y'
						)
					  )
			  )
			WHERE location_id NOT IN
			  (SELECT SUBSTR (cba.agency_location_code, 3)
			  FROM CE_BANK_ACCOUNTS CBA,
				HZ_PARTIES HP
			  WHERE hp.party_id =cba.bank_id
			  AND hp.party_name ='WELLS FARGO BANK'
			  AND hp.party_type ='ORGANIZATION'
			  AND HP.STATUS     ='A'
			  AND upper(cba.bank_Account_name) LIKE '%WELLS%'
			  AND cba.agency_location_code IS NOT NULL
			  )
			ORDER BY 1,  2;
			

		CURSOR c_store_deposit_bank
		IS
		SELECT sales_Date,
		  loc_id,
		  status_cd,
		  serial_num,
		  amount,
		  seq_nbr,
		  deposit_type,
		  location_id
		FROM
		  (SELECT DISTINCT /*+ INDEX(xcs,XX_CE_STORE_BANK_DEPOSITS_F3) */ sales_date,
			loc_id,
			status_cd,
			serial_num,
			amount ,
			seq_nbr,
			deposit_type,
			LPAD (TO_CHAR (xcs.loc_id), 6, '0') location_id
		  FROM xx_ce_store_bank_deposits xcs
		  WHERE NVL (status_cd, '~') =
			(SELECT XFTV.TARGET_value1
			FROM xx_fin_translatedefinition XFTD ,
			  xx_fin_translatevalues XFTV
			WHERE XFTD.translate_id   = XFTV.translate_id
			AND XFTD.translation_name = gc_trans_name
			AND XFTV.source_value1    = 'IN_STATUS_CODE'
			AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
			AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
			AND XFTV.enabled_flag = 'Y'
			AND XFTD.enabled_flag = 'Y'
			)
		  AND deposit_type NOT IN ('PTY','CHG')
		  AND EXISTS
			(SELECT 1
			FROM hr_all_organization_units hro
			WHERE hro.attribute1                                      = TO_CHAR(xcs.loc_id)
			AND xx_fin_country_defaults_pkg.f_org_id (hro.attribute5) = gn_org_id
			AND hro.TYPE                                             IN
			  (SELECT XFTV.TARGET_value1
			  FROM xx_fin_translatedefinition XFTD ,
				xx_fin_translatevalues XFTV
			  WHERE XFTD.translate_id   = XFTV.translate_id
			  AND XFTD.translation_name = gc_trans_name
			  AND XFTV.source_value1    = 'ORG_TYPE'
			  AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
			  AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
			  AND XFTV.enabled_flag = 'Y'
			  AND XFTD.enabled_flag = 'Y'
			  )
			)
		  )
		WHERE location_id NOT IN
			  (SELECT SUBSTR (cba.agency_location_code, 3)
			  FROM CE_BANK_ACCOUNTS CBA,
				HZ_PARTIES HP
			  WHERE hp.party_id =cba.bank_id
			  AND hp.party_name ='WELLS FARGO BANK'
			  AND hp.party_type ='ORGANIZATION'
			  AND HP.STATUS     ='A'
			  AND upper(cba.bank_Account_name) LIKE '%WELLS%'
			  AND cba.agency_location_code IS NOT NULL
			  )
	    ORDER BY 1,  2;
/****************************** R1.5 Cursur changes to exclude Wells Fargo Records Ends  *****************************/

/*****************R 1.2 CR 559 Fix****************Starts****************/
 -- Added Translation to Check the Starting Value of MIS Income Account
      CURSOR c_seg_acct
      IS
         SELECT XFTV.TARGET_value1
           FROM xx_fin_translatedefinition XFTD
               ,xx_fin_translatevalues XFTV
          WHERE XFTD.translate_id = XFTV.translate_id
            AND XFTD.translation_name = gc_trans_name
            AND XFTV.source_value1 = 'SEG_ACCT_SUBSTR'
            AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
            AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
            AND XFTV.enabled_flag = 'Y'
            AND XFTD.enabled_flag = 'Y';
/*****************R 1.2 CR 559 Fix****************Ends****************/

       -- 20080610 DGowda Performance Updates
      /* CURSOR c_change_deposit_accounts
       IS      --  Get the bank account for change fund and concentration trans
          SELECT DISTINCT csh.bank_account_id, aba.bank_account_num
                        , aba.bank_account_name, csh.statement_date
                        , gcc.segment1, gcc.segment2, gcc.segment3
                        , gcc.segment4, gcc.segment5, gcc.segment6
                        , gcc.segment7, gcck.segment1 conc1
                        , gcck.segment2 conc2, gcck.segment3 conc3
                        , gcck.segment4 conc4, gcck.segment5 conc5
                        , gcck.segment6 conc6, gcck.segment7 conc7
                        , aba.currency_code
                     FROM ce_statement_headers_all csh
                        , ce_statement_lines csl
                        , ce_transaction_codes ctc
                        , ap_bank_accounts_all aba
                        , gl_code_combinations gcc
                        , gl_code_combinations_kfv gcck
                    WHERE csl.trx_code_id = ctc.transaction_code_id
                      AND (   ctc.trx_code IN ('575', '366', '666', '629')
                           OR (    ctc.trx_code NOT IN
                                                  ('575', '366', '666', '629')
                               AND ctc.trx_type = 'CREDIT'
                               AND LENGTH (NVL (csl.invoice_text, '0')) = 10
                               AND SUBSTR (csl.invoice_text, 1, 2) = '33'
                              )
                          )
                      AND aba.bank_account_type = 'Deposit'
                      AND csl.statement_header_id = csh.statement_header_id
                      AND NVL (csl.attribute15, '~') <> 'PROC-E1318-YES'
                      AND aba.cash_clearing_ccid = gcc.code_combination_id
                      AND aba.bank_account_id = csh.bank_account_id
                      AND aba.attribute3 = gcck.concatenated_segments
                 ORDER BY csh.statement_date, aba.bank_account_num;
        */
     /*   CURSOR c_change_deposit_accounts     --Commented for the CR 559A --starts here--
      IS        --  Get the bank account for change fund and concentration trans
         SELECT   aba.bank_account_id, aba.bank_account_num
                , aba.bank_account_name                   --, csh.statement_date
                , gcc.segment1, gcc.segment2, gcc.segment3, gcc.segment4
                , gcc.segment5, gcc.segment6, gcc.segment7, gcck.segment1 conc1
                , gcck.segment2 conc2, gcck.segment3 conc3, gcck.segment4 conc4
                , gcck.segment5 conc5, gcck.segment6 conc6, gcck.segment7 conc7
                , aba.currency_code
             FROM ap_bank_accounts aba
                , gl_code_combinations gcc
                , gl_code_combinations_kfv gcck
            WHERE 1 = 1
              AND aba.attribute3 = gcck.concatenated_segments
              AND aba.cash_clearing_ccid = gcc.code_combination_id
              AND aba.bank_account_type = 'Deposit'
              AND aba.account_type = 'INTERNAL'
              AND EXISTS (
                    SELECT 1
                      FROM ce_statement_headers csh
                         , ce_statement_lines csl
                         , ce_transaction_codes ctc
                     WHERE csl.trx_code_id = ctc.transaction_code_id
                       AND csl.statement_header_id = csh.statement_header_id
                       AND NVL (csl.attribute15, '~') <> 'PROC-E1318-YES'
                       AND ctc.trx_code IN (
                             SELECT lookup_code                   --Defect 11020
                               FROM fnd_lookup_values flv
                              WHERE flv.lookup_type = 'XX_CE_ZBA_BANK_CODES'
                                AND enabled_flag = 'Y'
                                AND SYSDATE BETWEEN NVL (start_date_active
                                                       , SYSDATE - 1
                                                        )
                                                AND NVL (end_date_active
                                                       , SYSDATE + 1
                                                        ))
                                                          --AND ctc.trx_code = '575' --CR 423.
                 )
         ORDER BY aba.bank_account_num, aba.bank_account_name;    */--Commented for CR 559A--Ends here

      --                            AND csh.bank_account_id = aba.bank_account_id
      --                            AND(ctc.trx_code IN('575', '366', '666', '629')
      --                                OR(ctc.trx_code NOT IN
      --                                                    ('575', '366', '666', '629')
      --                                   AND ctc.trx_type = 'CREDIT'
      --                                   AND LENGTH(NVL(csl.invoice_text, '0') ) = 10
      --                                   AND SUBSTR(csl.invoice_text, 1, 2) = '33'
      --                                  )
      --                               )
  /*  CURSOR c_change_transactions  --Commented for CR 559A--starts here--
      IS
         SELECT   csl.statement_line_id, csl.line_number, ctc.trx_code
                , csl.amount, csl.trx_date, csl.invoice_text
                , csh.bank_account_id, csh.statement_date, csh.statement_number
             FROM ce_statement_lines csl
                , ce_statement_headers csh
                , ce_transaction_codes ctc
            WHERE csh.statement_header_id = csl.statement_header_id
              AND csh.bank_account_id = ln_bank_account_id
              AND NVL (csl.attribute15, '~') <> 'PROC-E1318-YES'
              AND csl.trx_code_id = ctc.transaction_code_id
              AND ctc.trx_code IN (
                    SELECT lookup_code                            --Defect 11020
                      FROM fnd_lookup_values flv
                     WHERE flv.lookup_type = 'XX_CE_ZBA_BANK_CODES'
                       AND enabled_flag = 'Y'
                       AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE - 1)
                                       AND NVL (end_date_active, SYSDATE + 1))
              --AND ctc.trx_code = '575'                                -- CR 423.
                       --  Defect 5883 If it's a 575,366,666, or 629 tran then process
                       --  or if it is not 575, 366,666 or 629 then also compare to the
                       --  invoice_text.  If first 2 digits (of MICR#) is 33, then process
         --              -- as '366'change fund.
         --              AND(ctc.trx_code IN('575', '366', '666', '629')
         --                  OR(ctc.trx_code NOT IN('575', '366', '666', '629')
         --                     AND ctc.trx_type = 'CREDIT'
         --                     AND LENGTH(NVL(csl.invoice_text, '0') ) = 10
         --                     AND SUBSTR(csl.invoice_text, 1, 2) = '33'
         --                    )
         --                 )
         ORDER BY csh.statement_date
                , csh.statement_number
                , csl.line_number
                , ctc.trx_code;  */  --Commented for CR 559A--ends here--

      CURSOR rpt_gl
      IS
         SELECT   a.user_je_category_name, a.user_je_source_name
                , COUNT ('x') gl_cnt, SUM (a.entered_cr) gl_cr
                , SUM (a.entered_dr) gl_dr, a.segment1, a.segment2, a.segment3
                , a.segment4, a.segment5, a.segment6
             FROM xx_gl_interface_na_stg a
            WHERE a.GROUP_ID = ln_group_id
         GROUP BY a.user_je_category_name
                , a.user_je_source_name
                , a.segment1
                , a.segment2
                , a.segment3
                , a.segment4
                , a.segment5
                , a.segment6;

     /* CURSOR distinct_mscc_accounts  --Commented for CR 559A--starts here--
        IS
          SELECT DISTINCT attribute3
                    FROM ap_bank_accounts
                   WHERE attribute3 IS NOT NULL
                     AND UPPER (bank_account_type) LIKE '%DEPOSIT%'; */  --Commented for CR 559A--Ends here--
--Defect 11531
      CURSOR c_check_db_status(lp_sales_date DATE, lp_loc_id NUMBER
      , lp_status_cd VARCHAR2, lp_serial_num VARCHAR2, lp_amount NUMBER
      , lp_seq_nbr NUMBER, lp_deposit_type VARCHAR2)
      IS
         SELECT 1

                    FROM xx_ce_store_bank_deposits xcs
                    WHERE xcs.sales_date = lp_sales_date
                      AND xcs.loc_id=lp_loc_id
                      AND xcs.status_cd=lp_status_cd
                      AND xcs.serial_num=lp_serial_num
                      AND xcs.amount=lp_amount
                      AND xcs.seq_nbr=lp_seq_nbr
                      AND xcs.deposit_type=lp_deposit_type
                      AND rownum=1;--Added due to the distinct clause in the cursor c_store_deposit_bank

      PROCEDURE lp_print (lp_line IN VARCHAR2, lp_both IN VARCHAR2)
      IS
         ln_addnl_line_len   NUMBER DEFAULT 110;
         ln_char_count       NUMBER := 0;
         ln_line_count       NUMBER := 0;
      BEGIN
         IF fnd_global.conc_request_id () > 0
         THEN
            CASE
               WHEN UPPER (lp_both) = 'BOTH'
               THEN
                  fnd_file.put_line (fnd_file.LOG, lp_line);

                  IF NVL (LENGTH (lp_line), 0) > 120
                  THEN
                     FOR x IN 1 .. (  TRUNC (  (LENGTH (lp_line) - 120)
                                             / ln_addnl_line_len
                                            )
                                    + 2
                                   )
                     LOOP
                        ln_line_count := NVL (ln_line_count, 0) + 1;

                        IF ln_line_count = 1
                        THEN
                           fnd_file.put_line (fnd_file.output
                                            , SUBSTR (lp_line, 1, 120)
                                             );
                           ln_char_count := NVL (ln_char_count, 0) + 120;
                        ELSE
                           fnd_file.put_line (fnd_file.output
                                            ,    LPAD (' '
                                                     , 120 - ln_addnl_line_len
                                                     , ' '
                                                      )
                                              || SUBSTR (LTRIM (lp_line)
                                                       , ln_char_count + 1
                                                       , ln_addnl_line_len
                                                        )
                                             );
                           ln_char_count :=
                                       NVL (ln_char_count, 0)
                                       + ln_addnl_line_len;
                        END IF;
                     END LOOP;
                  ELSE
                     fnd_file.put_line (fnd_file.output, lp_line);
                  END IF;
               WHEN UPPER (lp_both) = 'LOG'
               THEN
                  fnd_file.put_line (fnd_file.LOG, lp_line);
               WHEN UPPER (lp_both) = 'OUT'
               THEN
                  IF NVL (LENGTH (lp_line), 0) > 120
                  THEN
                     FOR x IN 1 .. (  TRUNC (  (LENGTH (lp_line) - 120)
                                             / ln_addnl_line_len
                                            )
                                    + 2
                                   )
                     LOOP
                        ln_line_count := NVL (ln_line_count, 0) + 1;

                        IF ln_line_count = 1
                        THEN
                           fnd_file.put_line (fnd_file.output
                                            , SUBSTR (lp_line, 1, 120)
                                             );
                           ln_char_count := NVL (ln_char_count, 0) + 120;
                        ELSE
                           fnd_file.put_line (fnd_file.output
                                            ,    LPAD (' '
                                                     , 120 - ln_addnl_line_len
                                                     , ' '
                                                      )
                                              || SUBSTR (LTRIM (lp_line)
                                                       , ln_char_count + 1
                                                       , ln_addnl_line_len
                                                        )
                                             );
                           ln_char_count :=
                                       NVL (ln_char_count, 0)
                                       + ln_addnl_line_len;
                        END IF;
                     END LOOP;
                  ELSE
                     fnd_file.put_line (fnd_file.output, lp_line);
                  END IF;
               ELSE
                  fnd_file.put_line (fnd_file.output, lp_line);
            END CASE;
         ELSE
            DBMS_OUTPUT.put_line (lp_line);
         END IF;
      END;       -- lp_print

   -- **************** Added procedure for null serial num replacement - CR 559A *******************

      PROCEDURE NULL_SER_NUM_REPLACE
      IS
        ln_ser_count                   VARCHAR2(4) := 0;
        lc_sc_serial_num               VARCHAR2(4);
        lc_sc_max_ser_num              NUMBER;

        BEGIN
          BEGIN
            SELECT SUBSTR(MAX(serial_num),2,3)
            INTO   lc_sc_max_ser_num
            FROM   xx_ce_store_bank_deposits
            WHERE  serial_num LIKE 'X%'
            AND    last_update_date =(SELECT MAX(last_update_date)
                                      FROM   xx_ce_store_bank_deposits
                                      WHERE  serial_num LIKE 'X%'
                                      );
          EXCEPTION
            WHEN OTHERS
            THEN
              lp_print ('When others exception has raised in MAX(serial_num) select statement.'|| SQLERRM , 'LOG');
              RAISE;

          END;

          IF lc_sc_max_ser_num IS NULL THEN --Added for the defect 14569.
            lc_sc_serial_num := 'X001';
          ELSIF lc_sc_max_ser_num = '0' THEN
           lc_sc_serial_num := 'X001';
          ELSIF lc_sc_max_ser_num = '00' THEN
           lc_sc_serial_num := 'X001';
          ELSIF lc_sc_max_ser_num = '000' THEN
           lc_sc_serial_num := 'X001';
          END IF;

          IF lc_sc_max_ser_num <> 999 THEN
            ln_ser_count := lc_sc_max_ser_num+1;
            lc_sc_serial_num := CONCAT('X',LPAD(ln_ser_count,3,0));
          ELSE
            lc_sc_serial_num := 'X001';
          END IF;

          -- Wait for 1 second if the lc_sc_max_ser_num = 999

          IF lc_sc_max_ser_num = 999 THEN
            lp_print('Waiting for a second in 999th record ','LOG');
            DBMS_LOCK.SLEEP(1);
          END IF;

          -- Updating the Serial Numbers for null serial numbers in xx_ce_store_bank_deposits table.

          UPDATE xx_ce_store_bank_deposits
          SET    serial_num       = lc_sc_serial_num
                ,last_update_date = SYSDATE
          WHERE  seq_nbr = ln_store_deposit_seq_nbr;

          lp_print ('Seq number: ' ||ln_store_deposit_seq_nbr|| 'Location: ' || ln_loc_id || '/ Sales date:'
                    || ld_sales_date||'  serial_num: '|| lc_sc_serial_num, 'LOG'
                   );
        EXCEPTION
          WHEN OTHERS
          THEN
            lp_print ('When others exception has raised in the procedure NULL_SER_NUM_REPLACE.'|| SQLERRM , 'LOG');
        END;

   -- **************** Added procedure for null serial num replacement - CR 559A Ends here ****************

      PROCEDURE lp_create_gl (
         lpv_dr                IN   NUMBER
       , lpv_cr                IN   NUMBER
       , lpv_accounting_date   IN   DATE
       , lpv_description       IN   VARCHAR2                      -- Defect 5942
      )
      /*-- -------------------------------------------
        -- Call the GL Common Package to create
        -- Gl Interface records
        -- -----------------------------------------*/
      IS
         ln_gl_ccid         NUMBER;
         lpv_char_date      VARCHAR2 (20);
         lpv_reference10    xx_gl_interface_na_stg.reference10%TYPE;
/*****************R 1.2 CR 559 Fix****************Starts****************/
 -- Added Local Variables
         lc_closing_status  GL_PERIOD_STATUSES.closing_status%TYPE;
         ld_accounting_date DATE;
         lc_source_name     VARCHAR2(25);
         lc_category_name   VARCHAR2(25);
/*****************R 1.2 CR 559 Fix****************Ends****************/
         ln_status_count    NUMBER;   --- Added for Defect#5189


      BEGIN
/*****************R 1.2 CR 559 Fix****************Starts****************/
 -- Added Translation for Hard Coded values used
         BEGIN
            SELECT XFTV.TARGET_value1
              INTO lc_source_name
              FROM xx_fin_translatedefinition XFTD
                   ,xx_fin_translatevalues XFTV
             WHERE XFTD.translate_id = XFTV.translate_id
               AND XFTD.translation_name = gc_trans_name
               AND XFTV.source_value1 = 'SOURCE_NAME'
               AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
               AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
               AND XFTV.enabled_flag = 'Y'
               AND XFTD.enabled_flag = 'Y';

            SELECT XFTV.TARGET_value1
              INTO lc_category_name
              FROM xx_fin_translatedefinition XFTD
                   ,xx_fin_translatevalues XFTV
             WHERE XFTD.translate_id = XFTV.translate_id
               AND XFTD.translation_name = gc_trans_name
               AND XFTV.source_value1 = 'CATEGORY_NAME'
               AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
               AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
               AND XFTV.enabled_flag = 'Y'
               AND XFTD.enabled_flag = 'Y';

         EXCEPTION
         WHEN NO_DATA_FOUND THEN
            lc_error_msg :=
                  'ERROR - Source and Category translation is not found.';
            lc_source_name := NULL;
            lc_category_name := NULL;
         WHEN OTHERS THEN
            lc_source_name := NULL;
            lc_category_name := NULL;
            lc_error_loc := 'LP_CREATE_GL - Source Name and Category Name: ' || lc_error_loc;
         END;
/*****************R 1.2 CR 559 Fix****************Ends****************/
  fnd_file.put_line (fnd_file.LOG,'lpv_accounting_date '|| lpv_accounting_date);

   fnd_file.put_line (fnd_file.LOG,'lc_source_name '|| lc_source_name);

  fnd_file.put_line (fnd_file.LOG,'lc_category_name '|| lc_category_name);


         lpv_char_date := TO_CHAR (lpv_accounting_date, 'YYYY-MM-DD');
         --  Call function to get line of business
         lc_seg_lob := pf_derive_lob (lc_seg_loc, lc_seg_cost);
         ln_gl_ccid :=
            fnd_flex_ext.get_ccid ('SQLGL'
                                      , 'GL#'
                                      , gn_coa_id
                                      , SYSDATE
                                      ,    lc_seg_co
                                        || '.'
                                        || lc_seg_cost
                                        || '.'
                                        || lc_seg_acct
                                        || '.'
                                        || lc_seg_loc
                                        || '.'
                                        || lc_seg_ic
                                        || '.'
                                        || lc_seg_lob
                                        || '.'
                                        || '000000'
                                       );

         IF NVL (ln_gl_ccid, 0) = 0
         THEN
            lc_error_msg := SUBSTR (fnd_flex_ext.GET_MESSAGE (), 1, 2500);
            lp_print (   'Code Combination for '
                      || lc_seg_co
                      || '.'
                      || lc_seg_cost
                      || '.'
                      || lc_seg_acct
                      || '.'
                      || lc_seg_loc
                      || '.'
                      || lc_seg_ic
                      || '.'
                      || lc_seg_lob
                      || '.'
                      || '000000'
                      || ' not found! '
                      || lc_error_msg
                    , 'BOTH'
                     );
            RAISE le_exception_gl_call;
         END IF;

/*****************R 1.2 CR 559 Fix****************Starts****************/
 -- Added Translation for Verifying the Status of the Period

 fnd_file.put_line (fnd_file.LOG,'lpv_accounting_date '|| lpv_accounting_date);
  fnd_file.put_line (fnd_file.LOG,'gn_set_of_bks_id '|| gn_set_of_bks_id);

         BEGIN
            SELECT closing_status
              INTO lc_closing_status
              FROM GL_PERIOD_STATUSES gp
             WHERE lpv_accounting_date BETWEEN start_date AND end_date
            ---------   AND set_of_books_id = gn_set_of_bks_id            ----Commented for R12 retrofit by Aradhna Sharma on 8-July-2013
	        AND ledger_id = gn_set_of_bks_id                           ----Added for R12 retrofit by Aradhna Sharma on 8-July-2013
               AND application_id = ln_appl_id;
         EXCEPTION
            WHEN OTHERS THEN
            lc_closing_status := 'C';
            lc_error_loc := 'LP_CREATE_GL - Closing Status for Accounting_Date: ' || lc_error_loc;
	      fnd_file.put_line (fnd_file.LOG,' error   '|| sqlerrm);

         END;
 fnd_file.put_line (fnd_file.LOG,'lc_closing_status '|| lc_closing_status);


         IF (lc_closing_status <> 'O') THEN
            ld_accounting_date := TRUNC(SYSDATE);
         ELSE
                  --- Added for Defect # 5189  *** Start***
                  --- Check the count of open periods
            SELECT COUNT(*)
            INTO ln_status_count
            FROM GL_PERIOD_STATUSES gp
            WHERE closing_status='O'
           ------- AND set_of_books_id = gn_set_of_bks_id   ----Commented for R12 retrofit by Aradhna Sharma on 8-July-2013
	   --AND lpv_accounting_date BETWEEN start_date AND end_date ----Added for R12 retrofit defect#26545 by Aradhna Sharma on 12-Dec-2013
																---commented the line as part of the defect#34104
	    AND ledger_id = gn_set_of_bks_id   ----Added for R12 retrofit by Aradhna Sharma on 8-July-2013
            AND application_id = ln_appl_id;

                  --- If only one period is open, pass Accounting Date as Sales Date

	    IF (ln_status_count=1)
            THEN
            ld_accounting_date := lpv_accounting_date;
            ELSE
                  --- If more than one period is open ,pass Accounting Date as Current Period(Sysdate)
            ld_accounting_date := TRUNC(SYSDATE);
            END IF;

                  --- Added for Defect # 5189 *** Ends***
         END IF;

	  fnd_file.put_line (fnd_file.LOG,'ld_accounting_date '|| ld_accounting_date);

/*****************R 1.2 CR 559 Fix****************Ends****************/

         -- Defect 10511 - Use Sysdate for Accounting date instead
         --              of Sales date.
         --  Call GL package to create the GL entry
         xx_gl_interface_pkg.create_stg_jrnl_line
                                     (p_status => 'NEW'
                                    , p_date_created => SYSDATE
                                    , p_created_by => ln_user_id
                                    , p_actual_flag => 'A'
                                    , p_group_id => ln_group_id
                                    , p_batch_name => lpv_char_date
                                    , p_batch_desc => ' '
/*****************R 1.2 CR 559 Fix****************Starts****************/
 -- Commented Hard Coded Values and Added Translation value
                                  /*  , p_user_source_name => 'OD CM POS'
                                    , p_user_catgory_name => 'Miscellaneous'*/
                                    , p_user_source_name => lc_source_name
                                    , p_user_catgory_name => lc_category_name
/*****************R 1.2 CR 559 Fix****************Ends****************/
                                    , p_set_of_books_id => ln_set_of_books_id
/*****************R 1.2 CR 559 Fix****************Starts****************/
 -- Commented Hard Coded Values and Added Translation value
                                   -- , p_accounting_date => TRUNC (SYSDATE) -- Commented for CR 559
                                    --lpv_accounting_date
                                    , p_accounting_date => ld_accounting_date -- Added for CR 559
/*****************R 1.2 CR 559 Fix****************Ends****************/
                                    , p_currency_code => lc_currency_code
                                    , p_company => lc_seg_co
                                    , p_cost_center => lc_seg_cost
                                    , p_account => lc_seg_acct
                                    , p_location => lc_seg_loc
                                    , p_intercompany => lc_seg_ic
                                    , p_channel => lc_seg_lob
                                    , p_future => '000000'
                                    , p_entered_dr => lpv_dr
                                    , p_entered_cr => lpv_cr
                                    , p_je_name => NULL
                                    , p_je_reference => ln_group_id
                                    , p_je_line_dsc => SUBSTR (lpv_description
                                                             , 1
                                                             , 240
                                                              )
                                    , x_output_msg => lc_output_msg
                                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            lc_oracle_error_msg := SQLERRM;
            lc_error_loc := 'LP_CREATE_GL: ' || lc_error_loc;
            RAISE le_exception_gl_call;
      END;                                       -- lp_create_gl local procedure

      PROCEDURE lp_get_store_data
      IS
      BEGIN
         SELECT aba.bank_account_id
	      , aba.bank_account_num
	      , aba.currency_code
              , hou.set_of_books_id     -------   aba.set_of_books_id   ----Changed for R12 retrofit by Aradhna Sharma on 8-July-2013
	      , cbau.org_id             -------  aba.org_id              ----Changed for R12 retrofit by Aradhna Sharma on 8-July-2013
	      , gcc.segment1
	      , gcc.segment2
              , gcc.segment3
	      , gcc.segment4
	      , gcc.segment5
	      , gcc.segment6
              , gcc.segment7
	      , gcc2.segment3
           INTO ln_bank_account_id, lc_bank_account_num, lc_currency_code
              , ln_set_of_books_id, ln_org_id, lc_seg_co, lc_seg_cost
              , lc_seg_acct, lc_seg_loc, lc_seg_ic, lc_seg_lob
              , lc_seg_fut, lc_store_cash_clearing
           FROM gl_code_combinations gcc
              , gl_code_combinations gcc2
            --------  , ap_bank_accounts aba       ----Commented for R12 retrofit by Aradhna Sharma on 8-July-2013
	      ,ce_bank_accounts  aba                ---- Added for R12 retrofit by Aradhna Sharma on 8-July-2013
	       ,ce_bank_acct_uses cbau                              ----Added for R12 retrofit by Aradhna Sharma on 8-July-2013
	       ,hr_operating_units hou                                  ----Added for R12 retrofit by Aradhna Sharma on 8-July-2013
          WHERE aba.asset_code_combination_id = gcc.code_combination_id
            AND aba.cash_clearing_ccid = gcc2.code_combination_id
            AND lc_aba_key = gcc.segment4
            -------AND NVL (aba.inactive_date, SYSDATE + 1) > TRUNC (SYSDATE)  ----Commented for R12 retrofit by Aradhna Sharma on 8-July-2013
	        AND NVL (cbau.end_date, SYSDATE + 1) > TRUNC (SYSDATE)   -- ADDED BY ROHIT NANDA ON 30-MAY-2017 V4.6 for Defect# 42107
	    AND NVL (aba.end_date, SYSDATE + 1) > TRUNC (SYSDATE)   ----- Added for R12 retrofit by Aradhna Sharma on 8-July-2013
	    AND aba.bank_account_id = cbau.bank_account_id             ----Added for R12 retrofit by Aradhna Sharma on 8-July-2013
	     AND hou.organization_id = cbau.org_id                      ----Added for R12 retrofit by Aradhna Sharma on 8-July-2013
            AND bank_account_type in ('Deposit','DEPOSIT')
            AND gcc.segment4 = SUBSTR (aba.agency_location_code, 3)
            AND gcc.segment4 =
                  SUBSTR (aba.bank_account_name_alt
                        , LENGTH (aba.bank_account_name_alt) - 5
                         )
            AND gcc.segment4 =
                  TRANSLATE (UPPER (aba.description)
                           , '0123456789ODEPITRS -'
                           , '0123456789'
                            )
            AND gcc.segment4 =
                  SUBSTR (aba.bank_account_name
                        , LENGTH (aba.bank_account_name) - 5
                         );

         lc_store_cash_account := lc_seg_acct;
         -- Hold the store's cash account
         lc_store_seg_cost := lc_seg_cost;       -- Hold the store's cost center
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            lc_error_msg :=
                  'ERROR - Bank account setup incorrectly for store : '
               || lc_aba_key;
            RAISE le_exception_bad_store;
         WHEN TOO_MANY_ROWS
         THEN
            lc_error_msg :=
                  'ERROR - Multiple bank accounts set up for store : '
               || lc_aba_key;
            RAISE le_exception_store_accounts;
      END;                                                  -- lp_get_store_data

      PROCEDURE lp_log_comn_error (
         lp_object_type   IN   VARCHAR2
       , lp_object_id     IN   VARCHAR2
      )
      IS
      BEGIN
         fnd_message.set_name ('XXFIN', 'XX_CE_STORE_OS_CC_PKG_ERR');
         fnd_message.set_token ('ERR_LOC', lc_error_loc);
         fnd_message.set_token ('ERR_ORA', lc_oracle_error_msg);
         --       lc_error_msg := FND_MESSAGE.GET;
         xx_com_error_log_pub.log_error
              (p_program_type => 'CONCURRENT PROGRAM'
             , p_program_name => 'OD: Store Over/Short and Cash Concentration'
             , p_program_id => fnd_global.conc_program_id
             , p_module_name => 'CE'
             , p_error_location => 'Error at ' || lc_error_loc
             , p_error_message_count => 1
             , p_error_message_code => 'E'
             , p_error_message => NVL (lc_error_msg, lc_oracle_error_msg)
             , p_error_message_severity => 'Major'
             , p_notify_flag => 'N'
             , p_object_type => lp_object_type
             , p_object_id => lp_object_id
              );
      END;                                                  -- lp_log_comn_error

      --  Create the CE Reconciliation Open Interface record
      --  and update the ce_statement_lines so they can be matched
      PROCEDURE create_open_interface (
         x_errbuf                OUT NOCOPY      VARCHAR2
       , x_retcode               OUT NOCOPY      NUMBER
       , p_trx_code_id           IN              NUMBER
       , p_trx_code              IN              VARCHAR2             ----Added for R12 retrofit by Aradhna Sharma on 19-Sep-2013 for Defect #25480
       , p_bank_trx_number_org   IN              VARCHAR2
       , p_statement_header_id   IN              NUMBER
       , p_statement_line_id     IN              NUMBER
       , p_record_type           IN              VARCHAR2
       , p_trx_date              IN              DATE
       , p_amount                IN              VARCHAR2
      )
      IS
         ln_transaction_code_id   NUMBER;
      BEGIN
               lp_print (' ln_bank_account_id :: '||ln_bank_account_id, 'LOG'); --Defect #41450
         SELECT xx_ce_999_interface_s.NEXTVAL
           INTO ln_seq_999
           FROM DUAL;

               lp_print (' ln_seq_999 :: '||ln_seq_999, 'LOG'); --Defect #41450
         BEGIN                             --  Get 001 trx_code_id for this bank
            SELECT
	        transaction_code_id
	       ,trx_code                            ----Added for R12 retrofit by Aradhna Sharma on 19-Sep-2013 for Defect #25480
                INTO ln_csl_trx_code_001_id
	             ,ln_csl_trx_code_001              ----Added for R12 retrofit by Aradhna Sharma on 19-Sep-2013 for Defect #25480
              FROM ce_transaction_codes
             WHERE bank_account_id = ln_bank_account_id
               AND trx_code = '001'
               AND NVL (end_date, SYSDATE + 1) > SYSDATE;
               lp_print (' ln_csl_trx_code_001_id :: '||ln_csl_trx_code_001_id, 'LOG'); --Defect #41450
               lp_print (' ln_csl_trx_code_001 :: '||ln_csl_trx_code_001, 'LOG'); --Defect #41450
         EXCEPTION
            WHEN OTHERS
            THEN
               x_retcode := ln_error;
               lc_error_loc := 'Get TrxCode:' || lc_error_loc;
               lc_oracle_error_msg := SQLERRM;

               lp_print (' ln_bank_account_id :: '||ln_bank_account_id, 'LOG'); --Defect #41450
               lp_print (' lc_oracle_error_msg :: '||lc_oracle_error_msg, 'LOG'); --Defect #41450
               lc_print_line :=
                     NVL (lc_oracle_error_msg, lc_error_msg)
                  || ' in '
                  || lc_error_loc;
               lp_print (lc_print_line, 'BOTH');
               --               lp_log_comn_error ('STORE OVER/SHORT - CC'
               --                                , 'Trx: Error trapped'
               --                                 );

               --  ***************************************************
--                 FOR TESTING ONLY
--      ln_csl_trx_code_001_id := 001 ;
--                 NEXT TWO LINES COMMENTED
--  ***************************************************
              --ROLLBACK;
               RAISE le_exception_trx_code;
         END;                            -- End of retrieve bank 001 trx_code_id

-- ------------------------------------------------
-- Insert the record into xx_ce_999_interface table
-- ------------------------------------------------

               lp_print (' xx_ce_999_interface :: ', 'LOG'); --Defect #41450
         INSERT INTO xx_ce_999_interface
                     (trx_id, trx_number, bank_trx_code_id_original
		    , bank_trx_code_original                          ----Added for R12 retrofit by Aradhna Sharma on 19-Sep-2013 for Defect #25480
		    , bank_trx_number_original, statement_header_id
                    , statement_line_id, record_type, creation_date
                    , created_by, last_update_date, last_updated_by, trx_type
                    , status, bank_account_id, currency_code
                    , trx_date, amount, match_amount, deposits_matched
                    , expenses_complete
                     )
              VALUES (ln_seq_999, ln_seq_999,
	              p_trx_code_id
		    ,  p_trx_code                                      ----Added for R12 retrofit by Aradhna Sharma on 19-Sep-2013 for Defect #25480
                    , p_bank_trx_number_org, p_statement_header_id
                    , p_statement_line_id, p_record_type, SYSDATE
                    , ln_user_id, SYSDATE, ln_user_id, 'CASH'
                    , 'FLOAT', ln_bank_account_id, lc_currency_code
                    , p_trx_date, p_amount, p_amount, 'Y'
                    , 'Y'
                     );

-- ------------------------------------------------
-- Update the ce_statement_lines record
-- ------------------------------------------------

               lp_print (' ce_statement_lines :: ', 'LOG'); --Defect #41450
         UPDATE ce_statement_lines csl
            SET csl.attribute15 = 'PROC-E1318-YES'
              , csl.trx_code_id = ln_csl_trx_code_001_id
	      , csl.trx_code = ln_csl_trx_code_001   ----Added for R12 retrofit by Aradhna Sharma on 19-Sep-2013 for Defect #25480
              , csl.bank_trx_number = ln_seq_999
          WHERE csl.statement_line_id = ln_csl_statement_line_id;
               lp_print (' updated :: ', 'LOG'); --Defect #41450
      EXCEPTION
         WHEN le_exception_trx_code
         THEN
            --NULL;
            RAISE;
         WHEN OTHERS
         THEN
            lc_oracle_error_msg := SQLERRM;
            x_retcode := ln_error;
            lc_error_loc := 'Write 999:' || lc_error_loc;
            lp_print (   NVL (lc_oracle_error_msg, lc_error_msg)
                      || ' in '
                      || lc_error_loc
                    , 'BOTH'
                     );
            --lp_log_comn_error ('STORE OVER/SHORT - CC', 'OI: Error trapped');
            --ROLLBACK;
            --RAISE le_exception_999;
            RAISE;
      END create_open_interface;

      PROCEDURE lp_translate (
         lp_source1      IN       VARCHAR2
       , lp_source2      IN       VARCHAR2
       , lp_out_cc       OUT      VARCHAR2
       , lp_out_acct     OUT      VARCHAR2
       , lp_tran_error   OUT      VARCHAR2
      )
      IS
         lp_out03              VARCHAR2 (100);
         lp_out04              VARCHAR2 (100);
         lp_out05              VARCHAR2 (100);
         lp_out06              VARCHAR2 (100);
         lp_out07              VARCHAR2 (100);
         lp_out08              VARCHAR2 (100);
         lp_out09              VARCHAR2 (100);
         lp_out10              VARCHAR2 (100);
         lp_out11              VARCHAR2 (100);
         lp_out12              VARCHAR2 (100);
         lp_out13              VARCHAR2 (100);
         lp_out14              VARCHAR2 (100);
         lp_out15              VARCHAR2 (100);
         lp_out16              VARCHAR2 (100);
         lp_out17              VARCHAR2 (100);
         lp_out18              VARCHAR2 (100);
         lp_out19              VARCHAR2 (100);
         lp_out20              VARCHAR2 (100);        --lp_ERR  varchar2(100) ;
         --lp_translate_name    VARCHAR2 (40)  := 'OD: CM INTEGRAL 2 ORA GL';
         lp_cc_translation     VARCHAR2 (40)   := 'GL_PSFIN_COST_CENTER';
         lp_acct_translation   VARCHAR2 (40)   := 'GL_PSFIN_ACCOUNT';
         lc_target1            VARCHAR2 (100);
         lc_target2            VARCHAR2 (100);
         lc_tran_err           VARCHAR2 (1000);
      BEGIN
         lp_print (   'Get translation for Legacy Dept/Acct:'
                   || lp_source1
                   || '/'
                   || lp_source2
                 , 'LOG'
                  );
         lp_out_cc := NULL;
         lp_out_acct := NULL;
         lc_target1 := NULL;
         lc_target2 := NULL;
         -- Get translation for the Department/Cost Center.
         xx_fin_translate_pkg.xx_fin_translatevalue_proc
                                       (p_translation_name => lp_cc_translation
                                      , p_source_value1 => lp_source1
                                      , x_target_value1 => lc_target1
                                      , x_target_value2 => lc_target2
                                      , x_target_value3 => lp_out03
                                      , x_target_value4 => lp_out04
                                      , x_target_value5 => lp_out05
                                      , x_target_value6 => lp_out06
                                      , x_target_value7 => lp_out07
                                      , x_target_value8 => lp_out08
                                      , x_target_value9 => lp_out09
                                      , x_target_value10 => lp_out10
                                      , x_target_value11 => lp_out11
                                      , x_target_value12 => lp_out12
                                      , x_target_value13 => lp_out13
                                      , x_target_value14 => lp_out14
                                      , x_target_value15 => lp_out15
                                      , x_target_value16 => lp_out16
                                      , x_target_value17 => lp_out17
                                      , x_target_value18 => lp_out18
                                      , x_target_value19 => lp_out19
                                      , x_target_value20 => lp_out20
                                      , x_error_message => lp_tran_error
                                       );
         lp_out_cc := NVL (lc_target1, lc_target2);
         lc_tran_err := lp_tran_error;
         lp_tran_error := NULL;
         lc_target1 := NULL;
         lc_target2 := NULL;
         -- Get translation for the Account.
         xx_fin_translate_pkg.xx_fin_translatevalue_proc
                                     (p_translation_name => lp_acct_translation
                                    , p_source_value1 => lp_source2
                                    , x_target_value1 => lc_target1
                                    , x_target_value2 => lc_target2
                                    , x_target_value3 => lp_out03
                                    , x_target_value4 => lp_out04
                                    , x_target_value5 => lp_out05
                                    , x_target_value6 => lp_out06
                                    , x_target_value7 => lp_out07
                                    , x_target_value8 => lp_out08
                                    , x_target_value9 => lp_out09
                                    , x_target_value10 => lp_out10
                                    , x_target_value11 => lp_out11
                                    , x_target_value12 => lp_out12
                                    , x_target_value13 => lp_out13
                                    , x_target_value14 => lp_out14
                                    , x_target_value15 => lp_out15
                                    , x_target_value16 => lp_out16
                                    , x_target_value17 => lp_out17
                                    , x_target_value18 => lp_out18
                                    , x_target_value19 => lp_out19
                                    , x_target_value20 => lp_out20
                                    , x_error_message => lp_tran_error
                                     );
         lp_out_acct := NVL (lc_target1, lc_target2);
         lp_tran_error := lc_tran_err || lp_tran_error;
         lp_print (   'Translated values for Dept/Acct:'
                   || NVL (lp_out_cc, 'NOT FOUND')
                   || '/'
                   || NVL (lp_out_acct, 'NOT FOUND')
                 , 'LOG'
                  );

         -- If no transalation error but a target value is not found
         --Then note error.
         IF (lp_out_cc IS NULL
             OR lp_out_acct IS NULL)
         THEN
            lp_print ('Error: Translation value(s) not found! ' || lp_tran_error
                    , 'LOG'
                     );
         END IF;
      END lp_translate;

      PROCEDURE lp_pty_mis
      IS
/*   ********************************************************** */
/*   *                                                        * */
/*   * This procedure creates GL entries for all 'PTY'        * */
/*   * and  'MIS' transactions.                               * */
/*   * It is called inside lp_process_store_receipt_os        * */
/*   ********************************************************** */
         CURSOR lc_pty_mis
         IS
            SELECT xcs.deposit_type, xcs.loc_id, xcs.sales_date
                 , SUBSTR (xcs.log_num, 4, 3) dept
                 , SUBSTR (xcs.bag_num, 4, 4)|| SUBSTR (xcs.log_num, 1, 3) acct
                 , xcs.amount
              FROM xx_ce_store_bank_deposits xcs
             WHERE xcs.deposit_type IN ('PTY', 'MIS')
               --AND TRUNC (xcs.sales_date) = ld_sales_date --Removed TRUNC for defect# 36086
			   AND xcs.sales_date = ld_sales_date
/*****************R 1.2 CR 559 Fix****************Starts****************/
 -- Commented Hard Coded Values and Added Translation
         --      AND NVL (xcs.status_cd, '~') NOT IN ('S', 'B')
               AND NVL (xcs.status_cd, '~') NOT IN(
                                         SELECT XFTV.TARGET_value1
                                           FROM xx_fin_translatedefinition XFTD
                                                ,xx_fin_translatevalues XFTV
                                          WHERE XFTD.translate_id = XFTV.translate_id
                                            AND XFTD.translation_name = gc_trans_name
                                            AND XFTV.source_value1 = 'EX_STATUS_CODE'
                                            AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                                            AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                                            AND XFTV.enabled_flag = 'Y'
                                            AND XFTD.enabled_flag = 'Y')
/*****************R 1.2 CR 559 Fix****************Ends****************/
               AND xcs.loc_id = ln_loc_id;

/*****************R 1.2 CR 559 Fix****************Starts****************/
 -- Added Local Variables
         ln_lr_loc    xx_ce_store_bank_deposits.loc_id%TYPE;
         ln_gr_loc    xx_ce_store_bank_deposits.loc_id%TYPE;
/*****************R 1.2 CR 559 Fix****************Ends****************/

      BEGIN
         lp_print ('Start PTY/MIS processing.', 'LOG');

/*****************R 1.2 CR 559 Fix****************Starts****************/
 -- Added Translation to get the account, cost center details
       BEGIN
         SELECT XFTV.TARGET_value2
                ,XFTV.TARGET_value3
         INTO   lc_trans_seg_acct
                ,lc_trans_seg_cost
         FROM   xx_fin_translatedefinition XFTD
               ,xx_fin_translatevalues XFTV
         WHERE  XFTD.translate_id = XFTV.translate_id
           AND  XFTD.translation_name = gc_trans_name
           AND  XFTV.source_value2 = 'PTY_CR'
           AND  SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
           AND  SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
           AND  XFTV.enabled_flag = 'Y'
           AND  XFTD.enabled_flag = 'Y';

         SELECT XFTV.TARGET_value1
           INTO ln_lr_loc
           FROM xx_fin_translatedefinition XFTD
                ,xx_fin_translatevalues XFTV
          WHERE XFTD.translate_id = XFTV.translate_id
            AND XFTD.translation_name = gc_trans_name
            AND XFTV.source_value1 = 'LR_LOC'
            AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
            AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
            AND XFTV.enabled_flag = 'Y'
            AND XFTD.enabled_flag = 'Y';

         SELECT XFTV.TARGET_value1
           INTO ln_gr_loc
           FROM xx_fin_translatedefinition XFTD
                ,xx_fin_translatevalues XFTV
          WHERE XFTD.translate_id = XFTV.translate_id
            AND XFTD.translation_name = gc_trans_name
            AND XFTV.source_value1 = 'GR_LOC'
            AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
            AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
            AND XFTV.enabled_flag = 'Y'
            AND XFTD.enabled_flag = 'Y';

       EXCEPTION
         WHEN NO_DATA_FOUND THEN
            lc_error_msg :=
                  'ERROR - Translation setup is not found : ';
            lc_trans_seg_acct := 00000;
            lc_trans_seg_cost := 00000;
            ln_lr_loc         := 99999;
            ln_gr_loc         := 00000;

         WHEN OTHERS THEN
            lc_trans_seg_acct := 00000;
            lc_trans_seg_cost := 00000;
            ln_lr_loc         := 99999;
            ln_gr_loc         := 00000;
            lc_error_loc := 'LC_PTY_MIS - Translation setup is not found: ' || lc_error_loc;
       END;
/*****************R 1.2 CR 559 Fix****************Ends****************/

         FOR ii IN lc_pty_mis
         LOOP                                     --  Get the PTY and MIS trans
            lc_translate_error := '~';

            BEGIN                                 --  Translate Integral Oracle
               lp_translate (LPAD (ii.dept, 4, '0')
                           , ii.acct
                           , lc_translate_seg_cost
                           , lc_translate_seg_acct
                           , lc_translate_error
                            );

               IF NVL (lc_translate_error, '~') <> '~'
               THEN
                  RAISE le_exception_translate;
               END IF;

               --  Do GL entry creation for this transaction
               IF ii.deposit_type = 'PTY'
               THEN
                  -- Do GL entries for this 'PTY' transaction
                  -- Always Credit store "Over/Short System" for the PTY trans amount
                  --  cost center is 43002 for acct 79612000 as per the defect 15006
                  lc_seg_loc := lc_aba_key;
/*****************R 1.2 CR 559 Fix****************Starts****************/
    -- Commented Hard Coded Values and Added Translation Values
         -- Changed seg_cost = 00000 and seg_acct = 10199700
              --    lc_seg_cost := '43002';  --Changed for the defect 15006 --43001
                  lc_seg_cost := lc_trans_seg_cost;
              --   lc_seg_acct := '79612000';
                  lc_seg_acct := lc_trans_seg_acct;
/*****************R 1.2 CR 559 Fix****************Ends****************/
                  lp_print('lc_seg_cost:'||lc_seg_cost,'BOTH');
                  lp_print('lc_seg_acct:'||lc_seg_acct,'BOTH');
                  -- Defect 5942
                  --lp_create_gl (0, ii.amount, ii.sales_date);
                  lc_je_line_dsc :=
                        lc_seg_loc
                     || '/'
                     || TO_CHAR (ii.sales_date, 'DD-MON-RR')
                     || '/'
                     || ' Petty Cash Dep';

                  lp_print('lc_je_line_dsc:'||lc_je_line_dsc,'BOTH');
                  lp_create_gl (0, ii.amount, ii.sales_date, lc_je_line_dsc);
                  lp_print('lc_je_line_dsc:'||lc_je_line_dsc,'LOG');
                  --  Now do the DR side
                  lc_seg_acct := lc_translate_seg_acct;

/*****************R 1.2 CR 559 Fix****************Starts****************/
 -- Added Translation to get Account, Cost center and Location Details
               BEGIN
                  SELECT XFTV.TARGET_value2
                         ,XFTV.TARGET_value3
                         ,XFTV.TARGET_value4
                    INTO lc_trans_seg_acct_dr
                         ,lc_trans_seg_cost_dr
                         ,lc_trans_seg_loc
                    FROM xx_fin_translatedefinition XFTD
                         ,xx_fin_translatevalues XFTV
                   WHERE XFTD.translate_id = XFTV.translate_id
                     AND XFTD.translation_name = gc_trans_name
                     AND XFTV.source_value2 = 'PTY_DR'
                     AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                     AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                     AND XFTV.enabled_flag = 'Y'
                     AND XFTD.enabled_flag = 'Y';
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     lc_error_msg :=
                        'ERROR - Translation setup is not found : ';
                     lc_trans_seg_acct_dr := 00000;
                     lc_trans_seg_cost_dr := 00000;
                     lc_trans_seg_loc  := 00000;

                  WHEN OTHERS THEN
                     lc_trans_seg_acct_dr := 00000;
                     lc_trans_seg_cost_dr := 00000;
                     lc_trans_seg_loc  := 00000;
                     lc_error_loc := 'LC_PTY_MIS ' || lc_error_loc;
               END;

      -- Commented the below hardcorded values and added with translation values
              --    IF lc_seg_acct = '10100530'                   -- Ca Debit Card
                  IF lc_seg_acct = lc_trans_seg_acct_dr
                  THEN                           -- gets done at corporate level
             --        lc_seg_cost := '00000';
             --        lc_seg_loc := '010000';
                     lc_seg_cost := lc_trans_seg_cost_dr;
                     lc_seg_loc := lc_trans_seg_loc;
/*****************R 1.2 CR 559 Fix****************Ends****************/
                     -- Defect 5942
                     -- lp_create_gl (ii.amount, 0, ii.sales_date);
                     lc_je_line_dsc :=
                           lc_seg_loc
                        || '/'
                        || TO_CHAR (ii.sales_date, 'DD-MON-RR')
                        || '/'
                        || ' CAD Debit Cards';
                  ELSE                             -- use the translate cost-ctr
                     lc_seg_cost := lc_translate_seg_cost;
                     lc_seg_loc := lc_aba_key;
                     -- Defect 5942
                     -- lp_create_gl (ii.amount, 0, ii.sales_date);
                     lc_je_line_dsc :=
                           lc_seg_loc
                        || '/'
                        || TO_CHAR (ii.sales_date, 'DD-MON-RR')
                        || '/'
                        || ' Misc Inc';
                  END IF;

                  lp_create_gl (ii.amount, 0, ii.sales_date, lc_je_line_dsc);
               --
               ELSIF ii.deposit_type = 'MIS'
               THEN
					   lb_flag := FALSE; --This needs to be initialized as FALSE. ----R 1.2 CR 559 Fix
                  -- Do GL entries for this 'MIS' transaction
                  lc_seg_loc := lc_aba_key;
                  lc_seg_cost := lc_translate_seg_cost;
                  lc_seg_acct := lc_translate_seg_acct;

/*****************R 1.2 CR 559 Fix****************Starts****************/
 -- Added Translation value for verifying the Starting value of the Account
                  FOR i IN c_seg_acct
                  LOOP
                     IF ((SUBSTR(lc_seg_acct,0,1)) = i.TARGET_value1) THEN
                        lb_flag := TRUE;
                     END IF;
                  END LOOP;

                  IF (lb_flag) THEN
                     SELECT XFTV.TARGET_value3
                       INTO lc_trans_seg_cost_mis
                       FROM xx_fin_translatedefinition XFTD
                            ,xx_fin_translatevalues XFTV
                      WHERE XFTD.translate_id = XFTV.translate_id
                        AND XFTD.translation_name = gc_trans_name
                        AND XFTV.source_value2 = 'MIS'
                        AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                        AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                        AND XFTV.enabled_flag = 'Y'
                        AND XFTD.enabled_flag = 'Y';

                     lc_seg_cost := lc_trans_seg_cost_mis;

                  END IF;
/*****************R 1.2 CR 559 Fix****************Ends****************/

                  -- Defect 5942
                  -- lp_create_gl (0, ii.amount, ii.sales_date);
                  lc_je_line_dsc :=
                        lc_seg_loc
                     || '/'
                     || TO_CHAR (ii.sales_date, 'DD-MON-RR')
                     || '/'
                     || ' Misc Expense';
                  --Credit translated account for the MIS trans amount
                  lp_create_gl (0, ii.amount, ii.sales_date, lc_je_line_dsc);

/*****************R 1.2 CR 559 Fix****************Starts****************/
 -- Added Translation to get the Account, Cost Center and Location Details
               BEGIN
                  SELECT XFTV.TARGET_value2
                         ,XFTV.TARGET_value3
                         ,XFTV.TARGET_value4
                    INTO lc_trans_seg_acct_mis_dr
                         ,lc_trans_seg_cost_mis_dr
                         ,lc_trans_seg_loc_mis_dr
                    FROM xx_fin_translatedefinition XFTD
                         ,xx_fin_translatevalues XFTV
                   WHERE XFTD.translate_id = XFTV.translate_id
                     AND XFTD.translation_name = gc_trans_name
                     AND XFTV.source_value2 = 'LOC'
                     AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                     AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                     AND XFTV.enabled_flag = 'Y'
                     AND XFTD.enabled_flag = 'Y';
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     lc_error_msg :=
                        'ERROR - Translation setup is not found : ';
                     lc_trans_seg_acct_mis_dr := 00000;
                     lc_trans_seg_cost_mis_dr := 00000;
                     lc_trans_seg_loc_mis_dr  := 00000;

                  WHEN OTHERS THEN
                     lc_trans_seg_acct_mis_dr := 00000;
                     lc_trans_seg_cost_mis_dr := 00000;
                     lc_trans_seg_loc_mis_dr  := 00000;
                     lc_error_loc := 'LC_PTY_MIS - MIS' || lc_error_loc;
               END;
                  -- Debit  store clearing account for the MIS trans amount
                  -- if not a CSC location, otherwise debit the account for
                  -- "Wachovia - Miscellaneous Corporate Deposits Clearing"
         -- Commented the below hardcorded values and added with translation
               /*   IF ii.loc_id < 2000
                     AND ii.loc_id > 999*/
                  IF ii.loc_id < ln_lr_loc
                     AND ii.loc_id > ln_gr_loc
                  THEN
/*                     lc_seg_loc := '010000';                  -- i.e. Corporate
                     lc_seg_cost := '00000';                                  --
                     lc_seg_acct := '10100314';*/
                     lc_seg_loc := lc_trans_seg_loc_mis_dr;
                     lc_seg_cost := lc_trans_seg_cost_mis_dr;
                     lc_seg_acct := lc_trans_seg_acct_mis_dr;
/*****************R 1.2 CR 559 Fix****************Ends****************/
                     -- Defect 5942
                     -- lp_create_gl (ii.amount, 0, ii.sales_date);
                     lc_je_line_dsc :=
                           lc_seg_loc
                        || '/'
                        || TO_CHAR (ii.sales_date, 'DD-MON-RR')
                        || '/'
                        || ' Misc Deposit';
                     lp_create_gl (ii.amount, 0, ii.sales_date, lc_je_line_dsc);
                  ELSE
                     lc_seg_loc := lc_aba_key;
                     lc_seg_cost := lc_store_seg_cost;
                     lc_seg_acct := lc_store_cash_clearing;
                     -- Defect 5942
                     -- lp_create_gl (ii.amount, 0, ii.sales_date);
                     lc_je_line_dsc :=
                           lc_seg_loc
                        || '/'
                        || TO_CHAR (ii.sales_date, 'DD-MON-RR')
                        || '/'
                        || ' Misc Deposit';
                     lp_create_gl (ii.amount, 0, ii.sales_date, lc_je_line_dsc);
                  END IF;                                     -- End of CSC test
               END IF;                               -- End of IF for trans type
            --            EXCEPTION
            --               WHEN OTHERS
            --               THEN
            --                  NULL;
            END;
         END LOOP;
      END lp_pty_mis;

/*   ********************************************************** */
/*   *                                                        * */
/*   * This procedure creates GL entries for all incoming     * */
/*   * transactions by:                                       * */
/*   *    a)  calling lp_pty_mis to do those trans types      * */
/*   *    b)  creating GL for all non 'PTY', 'MIS', 'CHG'     * */
/*   *                        'CHK', 'CSH', and other         * */
/*   *        transactions at a summary level                 * */
/*   * Then it determines any over/short condition between    * */
/*   * the store recorded deposits and the AR Cash Receipts   * */
/*   * for the day and creates appropriate GL entries.        * */
/*   *                                                        * */
/*   ********************************************************** */
      PROCEDURE lp_process_store_receipt_os
      IS
      BEGIN
         lc_error_loc := 'Store/Receipts Loop';
         ln_sum_petty := 0;
         ln_sum_cash_deposits := 0;
         ln_sum_check_deposits := 0;
         ln_sum_other_deposits := 0;
         ln_sum_misc_deposits := 0;
         /*  ****************************************************
         --  Call local procedure to Create Gl for PTY and MIS
         --  transactions.  Canadian Debit Cards are in PTY.   */
         lp_pty_mis;               --  This is the local procedure to do above.

/*****************R 1.2 CR 559 Fix****************Starts****************/
 -- Commented Hard Coded Values and Added Translation
      BEGIN
         SELECT XFTV.TARGET_value2
         INTO   lc_trans_seg_acct
         FROM   xx_fin_translatedefinition XFTD
               ,xx_fin_translatevalues XFTV
         WHERE  XFTD.translate_id = XFTV.translate_id
           AND  XFTD.translation_name = gc_trans_name
           AND  XFTV.source_value2 = 'DEPOSIT_STORE_CASH'
           AND  SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
           AND  SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
           AND  XFTV.enabled_flag = 'Y'
           AND  XFTD.enabled_flag = 'Y';
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            lc_error_msg :=
               'ERROR - Translation setup is not found : ';
            lc_trans_seg_acct := 00000;
         WHEN OTHERS THEN
            lc_trans_seg_acct := 00000;
            lc_error_loc := 'lp_process_store_receipt_os' || lc_error_loc;
      END;
/*****************R 1.2 CR 559 Fix****************Ends****************/

         SELECT                                                       --loc_id,
                SUM (DECODE (pd.deposit_type                -- Sum up Petty Cash
                           , 'PTY', pd.amount
                           , 0
                            )
                    ) pty
              , SUM (DECODE (pd.deposit_type             -- Sum up Misc Deposits
                           , 'MIS', pd.amount
                           , 0
                            )
                    ) mis
              , SUM (DECODE (pd.deposit_type                      -- Sum up Cash
                           , 'CSH', pd.amount
                           , 0
                            )) csh
              , SUM (DECODE (pd.deposit_type                     -- Sum up Check
                           , 'CHK', pd.amount
                           , 0
                            )
                    ) chk
              , SUM (DECODE (pd.deposit_type                -- Sum up all except
                           , 'PTY', 0                              -- Petty Cash
                           , 'CHG', 0                                  -- Change
                           , 'MIS', 0                           -- Misc Deposits
                           , 'CSH', 0                                    -- Cash
                           , 'CHK', 0                                  -- Checks
                           , pd.amount
                            )
                    ) other
           INTO ln_sum_petty
              , ln_sum_misc_deposits
              , ln_sum_cash_deposits
              , ln_sum_check_deposits
              , ln_sum_other_deposits
           FROM xx_ce_store_bank_deposits pd
       --   WHERE NVL (pd.status_cd, '~') NOT IN ('S', 'B') -- Commented and Added Translation for CR 559
          WHERE NVL (pd.status_cd, '~') NOT IN (
                                            SELECT XFTV.TARGET_value1
                                              FROM xx_fin_translatedefinition XFTD
                                                   ,xx_fin_translatevalues XFTV
                                             WHERE XFTD.translate_id = XFTV.translate_id
                                               AND XFTD.translation_name = gc_trans_name
                                               AND XFTV.source_value1 = 'EX_STATUS_CODE'
                                               AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                                               AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                                               AND XFTV.enabled_flag = 'Y'
                                               AND XFTD.enabled_flag = 'Y')
/*****************R 1.2 CR 559 Fix****************Ends****************/
            AND pd.loc_id = ln_loc_id
            --AND TRUNC (pd.sales_date) = ld_sales_date;  --Removed TRUNC for Defect# 36086
			AND pd.sales_date = ld_sales_date;

         -- Do GL entries for the cash, check, and other deposits
         -- but do not include the misc deposits since they
         -- will have different cost-centers, accounts etc.
         -- Debit store cash clearing acct for deposits
         lc_seg_loc := lc_aba_key;
         lc_seg_acct := lc_store_cash_clearing;
         lc_seg_cost := lc_store_seg_cost;
         lc_je_line_dsc :=
               lc_seg_loc
            || '/'
            || TO_CHAR (ld_sales_date, 'DD-MON-RR')
            || '/'
            || ' AR2 POS OvrShrt';

         IF ln_sum_cash_deposits > 0
         THEN
            lp_create_gl (ln_sum_cash_deposits
                        , 0
                        , ld_sales_date
                        , lc_je_line_dsc || '- Store Cash Deposit'
                         );
         END IF;

         IF ln_sum_check_deposits > 0
         THEN
            lp_create_gl (ln_sum_check_deposits
                        , 0
                        , ld_sales_date
                        , lc_je_line_dsc || '- Store Check Deposit'
                         );
         END IF;

         IF ln_sum_other_deposits > 0
         THEN
            lp_create_gl (ln_sum_other_deposits
                        , 0
                        , ld_sales_date
                        , lc_je_line_dsc || '- Store Other Deposit'
                         );
         END IF;

         -- Credit "Store Cash In Transit" acct for deposit amount
/*****************R 1.2 CR 559 Fix****************Starts****************/
 -- Commented Hard Coded Values and Added Translation Value
       --  lc_seg_acct := '10199700';
         lc_seg_acct := lc_trans_seg_acct;
/*****************R 1.2 CR 559 Fix****************Ends****************/

         IF ln_sum_cash_deposits > 0
         THEN
            -- lp_create_gl (0, ln_sum_cash_deposits, ld_sales_date);
            lp_create_gl (0
                        , ln_sum_cash_deposits
                        , ld_sales_date
                        , lc_je_line_dsc || '- Store Cash Deposit'
                         );
         END IF;

         IF ln_sum_check_deposits > 0
         THEN
            -- lp_create_gl (0, ln_sum_check_deposits, ld_sales_date);
            lp_create_gl (0
                        , ln_sum_check_deposits
                        , ld_sales_date
                        , lc_je_line_dsc || '- Store Check Deposit'
                         );
         END IF;

         IF ln_sum_other_deposits > 0
         THEN
            lp_create_gl (0
                        , ln_sum_other_deposits
                        , ld_sales_date
                        , lc_je_line_dsc || '- Store Other Deposit'
                         );
         END IF;

/*
--------------------------------------------------------------------------
-- 20080913
-- Start Removal of System Overshort - 20080913 - DGG
-- Above will be replaced by an export of Overshort from
-- Legacy Sales Accounting and interfaced to GL at a later date
--------------------------------------------------------------------------
  BEGIN                                          -- Get AR Receipts Total
     ln_sum_ar_receipts := 0;

     SELECT SUM (NVL (a.amount, 0))
       INTO ln_sum_ar_receipts
       FROM ar_cash_receipts a
          , ar_receipt_methods b
          , ar_receipt_classes c
      WHERE c.receipt_class_id = b.receipt_class_id
        AND a.attribute14 IN ('CASH', 'TELECHECK PAPER')
        AND a.amount != 0
        AND c.NAME LIKE '%OM%CASH%'
        AND a.receipt_method_id = b.receipt_method_id
        AND a.remittance_bank_account_id = ln_bank_account_id
        AND a.receipt_date = ld_sales_date;
  EXCEPTION
     WHEN OTHERS                               --  Includes no_data_found
     THEN                                                --  which is OK.
        ln_sum_ar_receipts := 0;
  END;                                           -- Get AR Receipts Total

  BEGIN                                           -- Get AR Returns Total
     ln_sum_ar_refunds := 0;

     SELECT SUM (DECODE (LOCATION
                       , lc_aba_key, DECODE (TRUNC (refund_date)
                                           , ld_sales_date, NVL
                                                          (credit_amount
                                                         , 0
                                                          )
                                           , 0
                                            )
                       , 0
                        )
                )
       INTO ln_sum_ar_refunds
       FROM (SELECT /*+ ordered use_nl(t r) */
/*                    t.credit_amount
                  , NVL (r.attribute1, r.attribute2) LOCATION
                  , NVL
                       ((SELECT actual_shipment_date
                           FROM oe_order_lines_all
                          WHERE header_id = t.header_id
                            AND actual_shipment_date IS NOT NULL
                            AND ROWNUM = 1)
                      , (SELECT ordered_date
                           FROM oe_order_headers_all
                          WHERE header_id = t.header_id)
                       ) refund_date
               FROM xx_om_return_tenders_all t
                  , ar_cash_receipts_all r
              WHERE t.cash_receipt_id = r.cash_receipt_id
                AND payment_type_code = 'CASH');

  EXCEPTION
     WHEN OTHERS                               --  Includes no_data_found
     THEN                                                --  which is OK.
        ln_sum_ar_refunds := 0;
  END;                                            -- Get AR Returns Total

  BEGIN                                  --Get Debit Card Cash back Total
     ln_sum_db_card_cash_backs := 0;

     SELECT SUM (  NVL (ool.unit_selling_price, 0)
                 * NVL (ool.ordered_quantity, 0)
                ) cashback_amt
       INTO ln_sum_db_card_cash_backs
       FROM oe_order_lines ool
      WHERE 1 = 1
        AND actual_shipment_date = ld_sales_date
        AND (ool.inventory_item_id, ool.ship_from_org_id) IN (
              SELECT msi.inventory_item_id, hro.organization_id
                FROM mtl_system_items_b msi
                   , hr_all_organization_units hro
                   , fnd_lookup_values flv
               WHERE 1 = 1
                 AND msi.organization_id = hro.organization_id
                 AND msi.segment1 = flv.lookup_code
                 AND flv.lookup_type = 'XX_CE_CASH_BACK_CODES'
                 AND flv.enabled_flag = 'Y'
                 AND hro.attribute1 = ln_loc_id);
  EXCEPTION
     WHEN OTHERS                               --  Includes no_data_found
     THEN                                                --  which is OK.
        ln_sum_db_card_cash_backs := 0;
  END;                                  -- Get Debit Card Cash back Total

  --   Calculate AR Receipts sum - store petty cash - store deposits.
  ln_store_receipts_difference :=
       ln_sum_ar_receipts
     - ln_sum_ar_refunds
     - ln_sum_db_card_cash_backs
     - ln_sum_petty
     - ln_sum_cash_deposits
     - ln_sum_check_deposits
     - ln_sum_other_deposits;
  lc_je_line_dsc :=
        lc_seg_loc
     || '/'
     || TO_CHAR (ld_sales_date, 'DD-MON-RR')
     || '/'
     || ' AR2 POS OvrShrt: AR Receipts:'
     || ln_sum_ar_receipts
     || ' /AR Refunds:'
     || ln_sum_ar_refunds
     || ' /AR Debit CashBack:'
     || ln_sum_db_card_cash_backs
     || ' /Store PTY:'
     || ln_sum_petty
     || ' /CSH:'
     || ln_sum_cash_deposits
     || ' /CHK:'
     || ln_sum_check_deposits
     || ' /OTH:'
     || ln_sum_other_deposits;

  -- ln_sum_misc_deposits; --Do not use MIS in over/short calculations.
  IF ln_store_receipts_difference = 0
  THEN
     NULL;
  --ELSIF ln_store_receipts_difference > 0  --Defect 5310.
  ELSIF ln_store_receipts_difference < 0
  THEN                       --  AR is less than Store
                             --  so credit store "Over/Short System" acct
                             --  cost center is 43001 for acct 79612000
     lc_seg_loc := lc_aba_key;
     lc_seg_acct := '79612000';
     lc_seg_cost := '43001';
     lp_create_gl (0
                 , ABS (ln_store_receipts_difference)
                 , ld_sales_date
                 , lc_je_line_dsc
                  );
     -- Debit "Store Cash In Transit" acct for deposit amount
     lc_seg_acct := '10199700';
     lc_seg_cost := lc_store_seg_cost;
     lp_create_gl (ABS (ln_store_receipts_difference)
                 , 0
                 , ld_sales_date
                 , lc_je_line_dsc
                  );
  --ELSIF ln_store_receipts_difference < 0  --Defect 5310.
  ELSIF ln_store_receipts_difference > 0
  THEN                        --  AR is more than Store
                              --  so debit store "Over/Short System" acct
                              --  cost center is 43001 for acct 79612000
     lc_seg_loc := lc_aba_key;
     lc_seg_acct := '79612000';
     lc_seg_cost := '43001';
     lp_create_gl (ABS (ln_store_receipts_difference)
                 , 0
                 , ld_sales_date
                 , lc_je_line_dsc
                  );
     -- Credit "Store Cash In Transit" acct for deposit amount
     lc_seg_acct := '10199700';
     lc_seg_cost := lc_store_seg_cost;
     lp_create_gl (0
                 , ABS (ln_store_receipts_difference)
                 , ld_sales_date
                 , lc_je_line_dsc
                  );
  END IF;                                      -- End Store - AR Receipts
*/
--------------------------------------------------------------------------
-- End Removal of System Overshort - 20080913 - DGG
-- Above will be replaced by an export of Overshort from
-- Legacy Sales Accounting and interfaced to GL at a later date
--------------------------------------------------------------------------
         UPDATE xx_ce_store_bank_deposits a
            SET a.status_cd = 'S'
              , a.status_date = SYSDATE
              , a.last_update_date = SYSDATE
              , a.last_updated_by = fnd_global.user_id
          WHERE a.loc_id = ln_loc_id
            AND a.sales_date = ld_sales_date
/*****************R 1.2 CR 559 Fix****************Starts****************/
 -- Commented Hard Coded Values and Added Translation
         --   AND NVL (a.status_cd, '~') IN ('~', '', ' ');
            AND NVL (a.status_cd, '~') IN (SELECT XFTV.TARGET_value1
                                             FROM xx_fin_translatedefinition XFTD
                                                   ,xx_fin_translatevalues XFTV
                                            WHERE XFTD.translate_id = XFTV.translate_id
                                              AND XFTD.translation_name = gc_trans_name
                                              AND XFTV.source_value1 = 'UPD_STATUS_CODE'
                                              AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                                              AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                                              AND XFTV.enabled_flag = 'Y'
                                              AND XFTD.enabled_flag = 'Y');
/*****************R 1.2 CR 559 Fix****************Ends****************/
      --COMMIT;
      EXCEPTION
         WHEN le_exception_translate
         THEN
            ln_sum_ar_receipts := 0;
            RAISE le_exception_translate;
         WHEN OTHERS
         THEN
            ln_sum_ar_receipts := 0;
            RAISE;
      END;                                        -- lp_Process_Store_Receipt_OS
/* ----------------------------------------------------*/
/*                                                     */
/*          START OF THE MAIN PROCEDURE                */
/*                                                     */
/* ----------------------------------------------------*/
   BEGIN                                         -- STORE_OS_CC_MAIN Starts Here
      lp_print ('Started at ' || TO_CHAR (SYSDATE, 'dd-mon-yyyy hh:mi:ss')
              , 'LOG'
               );
      lp_print ('', 'OUT');
      lc_print_line :=
            TO_CHAR (SYSDATE, 'DD-MON-YY')
         || '                              E1318-Store Over/Short and Cash Concentration';
      lp_print (lc_print_line, 'OUT');
      lp_print
         ('                                                       Processing Summary'
        , 'OUT'
         );
      lp_print (' ', 'BOTH');

   ----Added for R12 retrofit by Aradhna Sharma on 8-July-2013
        BEGIN
          mo_global.set_policy_context('S',FND_PROFILE.VALUE('ORG_ID'));
        END;


      SELECT gsob.chart_of_accounts_id
        INTO gn_coa_id
        FROM gl_ledgers gsob  ----------  gl_sets_of_books gsob  -- ----Changed for R12 retrofit by Aradhna Sharma on 8-July-2013
	, ar_system_parameters asp
       WHERE asp.set_of_books_id = gsob.ledger_id;

      SELECT gl_interface_control_s.NEXTVAL
        INTO ln_group_id
        FROM DUAL;

/*****************R 1.2 CR 559 Fix****************Starts****************/
 -- Commented Hard Coded Values and Added Translation
      SELECT application_id
        INTO ln_appl_id
        FROM fnd_application
       WHERE application_short_name = 'SQLGL';

      BEGIN
         SELECT XFTV.TARGET_value1
           INTO ln_days
           FROM xx_fin_translatedefinition XFTD
                ,xx_fin_translatevalues XFTV
          WHERE XFTD.translate_id = XFTV.translate_id
            AND XFTD.translation_name = gc_trans_name
            AND XFTV.source_value1 = 'NO_OF_DAYS'
            AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
            AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
            AND XFTV.enabled_flag = 'Y'
            AND XFTD.enabled_flag = 'Y';
      EXCEPTION
         WHEN OTHERS THEN
            ln_days := 0;
      END;
/*****************R 1.2 CR 559 Fix****************Ends****************/

      lp_print ('Group ID:' || ln_group_id, 'LOG');
      lc_error_loc := 'Store Deposit Loop';
      lp_print ('Process System Over/Short', 'BOTH');
      lp_print (gc_line, 'BOTH');
      lp_print (' ', 'BOTH');

      FOR sd IN c_store_deposit
      LOOP
         lc_aba_key := LPAD (TO_CHAR (sd.loc_id), 6, '0');
         ln_loc_id := sd.loc_id;
         ld_sales_date := TRUNC (sd.sales_date);
         lc_status_cd := NVL (sd.status_cd, '~');
         lp_print ('', 'LOG');
         lp_print (gc_line, 'LOG');
         lp_print (   'Process location:'
                   || lc_aba_key
                   || ' / Sales Date:'
                   || ld_sales_date
                 , 'LOG'
                  );
         ln_rec_count := NVL (ln_rec_count, 0) + 1;

         IF ln_rec_count = 1
         THEN
            lp_print (   RPAD (' Store #', 9, ' ')
                      || '  '
                      || RPAD ('Date', 9, ' ')
                      || '  '
                      || 'Error'
                    , 'OUT'
                     );
            lp_print (   LPAD ('-', 9, '-')
                      || '  '
                      || LPAD ('-', 9, '-')
                      || '  '
                      || LPAD ('-', 70, '-')
                    , 'OUT'
                     );
         END IF;

         BEGIN                                             -- Process Store Data
            lc_st_dep_savepoint :=
                              'Savepoint-' || ln_loc_id || '-' || ld_sales_date;
            SAVEPOINT lc_st_dep_savepoint;
            -- Get bank data for this store
            lp_get_store_data;                  -- Get bank data for this store
            --  Process Store to AR receipts Compare
            --  will not happen if get Store Bank Account data failed.
            lp_print ('Process Store Deposits', 'LOG');
            lp_process_store_receipt_os;                     -- Local Procedure
            lp_print (   LPAD (lc_aba_key, 9, ' ')
                      || '  '
                      || LPAD (ld_sales_date, 9, ' ')
                      || '  Processed.'
                    , 'OUT'
                     );
         --            EXCEPTION
         --               WHEN OTHERS
         --               THEN
         --                  NULL;
                                   --  End Process Store to AR receipts Compare
         EXCEPTION
            WHEN le_exception_translate
            THEN
               lp_print
                  (   LPAD (ld_sales_date, 9, ' ')
                   || '  '
                   || LPAD (lc_aba_key, 9, ' ')
                   || '  Error getting translation value(s). Review log for details.'
                 , 'OUT'
                  );
               ROLLBACK TO lc_st_dep_savepoint;
            WHEN le_exception_bad_store
            THEN
               lc_error_loc := 'Store Deposit LOOP:lp_get_store_data';
               lp_print (lc_error_msg, 'LOG');
               lp_print (   LPAD (ld_sales_date, 9, ' ')
                         || '  '
                         || LPAD (lc_aba_key, 9, ' ')
                         || '  Bank account setup incorrectly for store.'
                       , 'OUT'
                        );
               ROLLBACK TO lc_st_dep_savepoint;
            WHEN le_exception_store_accounts
            THEN
               lc_error_loc := 'Store Deposit LOOP:lp_get_store_data';
               lp_print (lc_error_msg, 'LOG');
               lp_print (   LPAD (ld_sales_date, 9, ' ')
                         || '  '
                         || LPAD (lc_aba_key, 9, ' ')
                         || '  Multiple bank accounts set up for store.'
                       , 'OUT'
                        );
               ROLLBACK TO lc_st_dep_savepoint;
            WHEN OTHERS
            THEN
               lp_print (   LPAD (ld_sales_date, 9, ' ')
                         || '  '
                         || LPAD (lc_aba_key, 9, ' ')
                         || '  Error processing store deposits. '
                         || SQLCODE
                         || '-'
                         || SQLERRM
                       , 'LOG'
                        );
               ROLLBACK TO lc_st_dep_savepoint;
         END;                                          -- End Process Store Data

      END LOOP;                                                                --

      --  Process Bank to Store (Manual) Over/Shorts
      lc_error_loc := 'Store-Bank O/S Loop';
      lp_print ('', 'BOTH');
      lp_print ('', 'BOTH');
      lp_print ('Process Manual/Bank Over-Short(s)', 'BOTH');
      lp_print (gc_line, 'BOTH');
      lp_print ('', 'BOTH');
      ln_rec_count := 0;

/*****************R 1.2 CR 559 Fix****************Starts****************/
 -- Updates the PTY Transactions before matching criteria starts
      UPDATE xx_ce_store_bank_deposits xcs
         SET xcs.status_cd = 'B'
       WHERE xcs.deposit_type = 'PTY'
         AND xcs.status_cd IN (
                               SELECT XFTV.TARGET_value1
                                 FROM xx_fin_translatedefinition XFTD
                                      ,xx_fin_translatevalues XFTV
                                WHERE XFTD.translate_id = XFTV.translate_id
                                  AND XFTD.translation_name = gc_trans_name
                                  AND XFTV.source_value1 = 'IN_STATUS_CODE'
                                  AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                                  AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                                  AND XFTV.enabled_flag = 'Y'
                                  AND XFTD.enabled_flag = 'Y');

      COMMIT;
/*****************R 1.2 CR 559 Fix****************Ends****************/

      FOR sdb IN c_store_deposit_bank       -- All POS/SA deposit lines that are
      LOOP                                    -- not 'PTY' or 'CHG' deposit type
                                              -- and status code = 'S'
--Defect #11531
      FOR cds IN c_check_db_status(sdb.sales_date , sdb.loc_id
      , sdb.status_cd , sdb.serial_num , sdb.amount
      , sdb.seq_nbr , sdb.deposit_type )
      LOOP


         BEGIN
/*****************R 1.2 CR 559 Fix****************Starts****************/
 -- Added Local Variable to check whether the record has passed to the matching criteria
            lc_flag := 'N';
/*****************R 1.2 CR 559 Fix****************Ends****************/
            lc_aba_key := LPAD (TO_CHAR (sdb.loc_id), 6, '0');
			lc_error_loc :=Null;
            ln_loc_id := sdb.loc_id;
            ld_sales_date := TRUNC (sdb.sales_date);
            lc_status_cd := NVL (sdb.status_cd, '~');
            lc_serial_num := LPAD (sdb.serial_num, 4, '0');
            lc_serial_loc := lc_serial_num || SUBSTR (lc_aba_key, 3, 4);
            ln_store_amount := sdb.amount;
            ln_store_deposit_seq_nbr := sdb.seq_nbr;

            -- Added for CR 559A - Start


            IF (NVL(sdb.SERIAL_NUM,'NULL') IN ('NULL','0','00','000','0000')) THEN  --Added for the defect 14569.

                lp_print(sdb.SERIAL_NUM,'BOTH');

                NULL_SER_NUM_REPLACE;  -- Calling the procedure - NULL_SER_NUM_REPLACE

            END IF;
            -- Added for CR 559A - End

            lp_print (' ', 'LOG');
            lp_print (gc_line, 'LOG');
            lp_print ('Location: ' || ln_loc_id || '/ Sales date:'
                      || ld_sales_date
                    , 'LOG'
                     );
            lc_sdb_savepoint :=
                  'Savepoint_'
               || ln_loc_id
               || '-'
               || ld_sales_date
               || '-'
               || lc_serial_num
               || '-'
               || ln_store_deposit_seq_nbr;
            --lp_print ('Set Savepoint: ' || lc_sdb_savepoint, 'LOG');
            SAVEPOINT lc_sdb_savepoint;
            ln_rec_count := NVL (ln_rec_count, 0) + 1;
            lp_print (' ln_rec_count :: '||ln_rec_count, 'LOG'); --Defect #41450

            IF ln_rec_count = 1
            THEN
/*****************R 1.2 CR 559 Fix****************Starts****************/
-- Formatted the output
               lp_print (   RPAD (' Store #', 9, ' ')
                         || '  '
                         || RPAD (' Sales Date', 11, ' ')
                         || '  '
                         || RPAD (' Bank Stmt Date', 15, ' ')
                         || '  '
                         || LPAD (' Seq #', 9, ' ')
                         || '   Error'
                       , 'OUT'
                        );
               lp_print (   LPAD ('-', 9, '-')
                         || '  '
                         || LPAD ('-', 11, '-')
                         || '  '
                         || LPAD ('-', 15, '-')
                         || '  '
                         || LPAD ('-', 9, '-')
                         || '  '
                         || LPAD ('-', 50, '-')
                       , 'OUT'
                        );
/*****************R 1.2 CR 559 Fix****************Ends****************/
            END IF;

            -- Get bank data for this store
            lp_print (' lp_get_store_data :: '||lc_error_loc, 'LOG'); --Defect #41450
            lp_get_store_data;

            lp_print ('lp_get_store_data :: '||lc_error_loc, 'LOG');
            BEGIN                --  MATCH TO BAI DEPOSIT
                                 --  Get statement lines with dff15 blank
                                 --  If 'MIS' type just set up for GL creation.
                                 --  If other type then do the
                                 --  NOTE:  The 2 may change to a 1 or an alpha.

/*****************R 1.2 CR 559 Fix****************Starts****************/
 -- Commented and Added Three other matching criteria's
/*               IF sdb.deposit_type = 'MIS'
               THEN
                  BEGIN                                         --  MATCH 'MIS'
                     --  try to find this deposit in the Bank statement deposits
                     --  over the next six days(?).  If found then then create
                     --  a CE Reconciliation Open Interface record matching the
                     --  bank deposit so that the statement line gets reconciled.
                     SELECT csl.amount          --  NO_DATA_FOUND for this is OK
                          , csl.statement_line_id, csl.trx_code_id
                          , csl.bank_trx_number
                          , csl.statement_header_id, csl.invoice_text
                          , csl.bank_account_text, csl.customer_text
                          , csl.trx_date
                       INTO ln_csl_deposit_amt
                          , ln_csl_statement_line_id, ln_csl_trx_code_id
                          , lc_csl_bank_trx_number
                          , ln_csl_statement_header_id, lc_csl_invoice_text
                          , lc_csl_bank_account_text, lc_csl_customer_text
                          , ld_csl_trx_date
                       FROM ap_bank_accounts aba
                          , ce_statement_headers csh
                          , ce_statement_lines csl
                          , ce_transaction_codes ctc
                      WHERE NVL (csl.attribute15, '~') = '~'
                        AND csl.statement_header_id = csh.statement_header_id
                        AND csh.bank_account_id = aba.bank_account_id
                        AND csh.bank_account_id = ln_bank_account_id
                        AND csl.trx_code_id = ctc.transaction_code_id
                        AND ctc.bank_account_id = csh.bank_account_id
                        AND ctc.reconcile_flag = 'OI'        -- Added for the defect 15329
                        -- AND TRUNC (csl.trx_date) < ld_sales_date + 7
                                                AND TRUNC (csl.trx_date) < ld_sales_date + 30  --- Defect 833
                        AND csl.amount = ln_store_amount;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        RAISE le_exception_no_match;
                  END;                                           --  MATCH 'MIS'
               ELSE       --  If not a 'MIS' type deposit then we just
                          --  want to match the store-bank-deposit record with
                          --  a statement deposit line using the deposit
                          --  slip serial number matching
                          --  invoice text =  trim last 4 of serial
                          --  || last 4 of store num or same with a 2 after that
                          --  NOTE:  The 2 may change to a 1 or an alpha.
                  BEGIN                            --   MATCH OTHER TRANS TYPES
                     SELECT csl.amount          --  NO_DATA_FOUND for this is OK
                          , csl.statement_line_id, csl.trx_code_id
                          , csl.bank_trx_number
                          , csl.statement_header_id, csl.invoice_text
                          , csl.bank_account_text, csl.customer_text
                          , csl.trx_date
                       INTO ln_csl_deposit_amt
                          , ln_csl_statement_line_id, ln_csl_trx_code_id
                          , lc_csl_bank_trx_number
                          , ln_csl_statement_header_id, lc_csl_invoice_text
                          , lc_csl_bank_account_text, lc_csl_customer_text
                          , ld_csl_trx_date
                       FROM ap_bank_accounts aba
                          , ce_statement_headers csh
                          , ce_statement_lines csl
                          , ce_transaction_codes ctc
                      WHERE NVL (csl.attribute15, '~') = '~'
                        AND csl.statement_header_id = csh.statement_header_id
                        AND csh.bank_account_id = aba.bank_account_id
                        AND csh.bank_account_id = ln_bank_account_id
                        AND csl.trx_code_id = ctc.transaction_code_id
                        AND ctc.bank_account_id = csh.bank_account_id
                        AND ctc.reconcile_flag = 'OI'          -- Added for the defect 15329
                        AND ((SUBSTR (csl.invoice_text
                                    , LENGTH (csl.invoice_text) - 8
                                    , 9
                                     ) = lc_serial_loc || '2'
                             )
                             OR (SUBSTR (csl.invoice_text
                                       , LENGTH (csl.invoice_text) - 7
                                       , 8
                                        ) = lc_serial_loc
                                )
                            );*/
            lp_print (' lc_flag :: '||lc_flag, 'LOG'); --Defect #41450

               IF lc_flag = 'N' THEN
                  BEGIN
                     SELECT /*+ leading(csh) ordered use_nl(csh,csl,ctc) index(csl,CE_STATEMENT_LINES_N1) index(CSH,CE_STATEMENT_HEADERS_U2) */
							csl.amount
                           ,csl.statement_line_id
                           ,csl.trx_code_id
                           ,csl.trx_code               ----Added for R12 retrofit by Aradhna Sharma on 19-Sep-2013 for Defect #25480
                           ,csl.bank_trx_number
                           ,csl.statement_header_id
                           ,csl.invoice_text
                           ,csl.bank_account_text
                           ,csl.customer_text
                           ,csl.trx_date
                           ,csh.statement_date
                       INTO ln_csl_deposit_amt
                           ,ln_csl_statement_line_id
                           ,ln_csl_trx_code_id
			   ,ln_csl_trx_code             ----Added for R12 retrofit by Aradhna Sharma on 19-Sep-2013 for Defect #25480
                           ,lc_csl_bank_trx_number
                           ,ln_csl_statement_header_id
                           ,lc_csl_invoice_text
                           ,lc_csl_bank_account_text
                           ,lc_csl_customer_text
                           ,ld_csl_trx_date
                           ,ld_bank_statement_date
                      FROM --------ap_bank_accounts aba                      ----commented for R12 retrofit by Aradhna Sharma on 8-July-2013
		           ce_bank_accounts aba                              ----Added for R12 retrofit by Aradhna Sharma on 8-July-2013
                          ,ce_statement_headers csh
                          ,ce_statement_lines csl
                          ,ce_transaction_codes ctc
                     WHERE NVL (csl.attribute15, '~') = '~'
                       AND csl.statement_header_id = csh.statement_header_id
                       AND csh.bank_account_id = aba.bank_account_id
                       AND aba.bank_account_type in ('Deposit','DEPOSIT')   -- Including account type lookup 'DEPOSIT' for defect# 32125
                       AND LPAD(TO_CHAR(ln_loc_id),6,'0') = SUBSTR (aba.agency_location_code,3)
                       AND LPAD(TO_CHAR(ln_loc_id),6,'0') = SUBSTR (aba.bank_account_name_alt
                                                           ,LENGTH (aba.bank_account_name_alt)-5)
                       AND LPAD(TO_CHAR(ln_loc_id),6,'0') = TRANSLATE (UPPER (aba.description)
                                                             ,'0123456789ODEPITRS -'
                                                             ,'0123456789')
                       AND LPAD(TO_CHAR(ln_loc_id),6,'0') = SUBSTR (aba.bank_account_name
                                                             ,LENGTH (aba.bank_account_name)-5)
                       AND csh.bank_account_id = ln_bank_account_id
                        --------------AND csl.trx_code_id = ctc.transaction_code_id          ----Commented  for R12 retrofit by Aradhna Sharma on 19-Sep-2013 for Defect #25480
		       AND csl.trx_code = ctc.trx_code                                        --------Added for R12 retrofit by Aradhna Sharma on 19-Sep-2013 for Defect #25480
                       AND csl.status!='RECONCILED'                                 --Added for defect#7656
                       AND ctc.bank_account_id = csh.bank_account_id
                       AND ctc.reconcile_flag = 'OI'
                       AND csl.amount = ln_store_amount
                       AND rownum = 1;
                       lc_flag := 'Y';
                       lc_match_type := 'Exact Amount Match!';
            lp_print (' lc_match_type :: '||lc_match_type, 'LOG'); --Defect #41450
                  EXCEPTION
                     WHEN OTHERS
                     THEN

						lp_print (' Exact MAtch :: '||SQLERRM, 'LOG');--Defect #41450
                  END;
               END IF;
            lp_print (' lc_flag 1 :: '||lc_flag, 'LOG'); --Defect #41450

               IF lc_flag = 'N' THEN
                  BEGIN
                     SELECT SUM (pd.amount) total_amount
                       INTO ln_sum_cash_check_deposits
                       FROM xx_ce_store_bank_deposits pd
                      WHERE NVL (pd.status_cd, '~') = (
                                            SELECT XFTV.TARGET_value1
                                              FROM xx_fin_translatedefinition XFTD
                                                   ,xx_fin_translatevalues XFTV
                                             WHERE XFTD.translate_id = XFTV.translate_id
                                               AND XFTD.translation_name = gc_trans_name
                                               AND XFTV.source_value1 = 'IN_STATUS_CODE'
                                               AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                                               AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                                               AND XFTV.enabled_flag = 'Y'
                                               AND XFTD.enabled_flag = 'Y')
                        AND pd.loc_id = ln_loc_id
                        AND pd.deposit_type IN (SELECT XFTV.TARGET_value1
                                                  FROM xx_fin_translatedefinition XFTD
                                                      ,xx_fin_translatevalues XFTV
                                                WHERE XFTD.translate_id = XFTV.translate_id
                                                  AND XFTD.translation_name = gc_trans_name
                                                  AND XFTV.source_value1 = 'MULTI_MATCH'
                                                  AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                                                  AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                                                  AND XFTV.enabled_flag = 'Y'
                                                  AND XFTD.enabled_flag = 'Y')
                        --AND TRUNC (pd.sales_date) = ld_sales_date;  --Removed TRUNC for defect# 36086
						AND pd.sales_date = ld_sales_date;

                     lp_print (' ld_sales_date :: '||ld_sales_date, 'LOG'); --Defect #41450

                    lp_print ('lc flag is N :: '||lc_error_loc, 'LOG'); --Defect #41450
                     SELECT /*+ leading(csh) ordered use_nl(csh,csl,ctc) index(csl,CE_STATEMENT_LINES_N1) index(CSH,CE_STATEMENT_HEADERS_U2) */
					        csl.amount
                           ,csl.statement_line_id
                           ,csl.trx_code_id
			   ,csl.trx_code                     ----Added for R12 retrofit by Aradhna Sharma on 19-Sep-2013 for Defect #25480
                           ,csl.bank_trx_number
                           ,csl.statement_header_id
                           ,csl.invoice_text
                           ,csl.bank_account_text
                           ,csl.customer_text
                           ,csl.trx_date
                           ,csh.statement_date
                       INTO ln_csl_deposit_amt
                           ,ln_csl_statement_line_id
                           ,ln_csl_trx_code_id
			   ,ln_csl_trx_code           ----Added for R12 retrofit by Aradhna Sharma on 16-Sep-2013
                           ,lc_csl_bank_trx_number
                           ,ln_csl_statement_header_id
                           ,lc_csl_invoice_text
                           ,lc_csl_bank_account_text
                           ,lc_csl_customer_text
                           ,ld_csl_trx_date
                           ,ld_bank_statement_date
                       FROM -------ap_bank_accounts aba                      ----commented for R12 retrofit by Aradhna Sharma on 8-July-2013
		            ce_bank_accounts aba                              ----Added for R12 retrofit by Aradhna Sharma on 8-July-2013
                           ,ce_statement_headers csh
                           ,ce_statement_lines csl
                           ,ce_transaction_codes ctc
                      WHERE NVL (csl.attribute15, '~') = '~'
                        AND csl.statement_header_id = csh.statement_header_id
                        AND csh.bank_account_id = aba.bank_account_id
                        AND aba.bank_account_type in ('Deposit','DEPOSIT')   -- Including account type lookup 'DEPOSIT' for defect# 32125
                        AND LPAD(TO_CHAR(ln_loc_id),6,'0') = SUBSTR (aba.agency_location_code,3)
                        AND LPAD(TO_CHAR(ln_loc_id),6,'0') = SUBSTR (aba.bank_account_name_alt
                                                            ,LENGTH (aba.bank_account_name_alt)-5)
                        AND LPAD(TO_CHAR(ln_loc_id),6,'0') = TRANSLATE (UPPER (aba.description)
                                                             ,'0123456789ODEPITRS -'
                                                             ,'0123456789')
                        AND LPAD(TO_CHAR(ln_loc_id),6,'0') = SUBSTR (aba.bank_account_name
                                                             ,LENGTH (aba.bank_account_name)-5)
                        AND csh.bank_account_id = ln_bank_account_id
                     ---------   AND csl.trx_code_id = ctc.transaction_code_id    ----Commented for R12 retrofit by Aradhna Sharma on 19-Sep-2013 for Defect #25480
			AND csl.trx_code = ctc.trx_code    ----Added for R12 retrofit by Aradhna Sharma on 19-Sep-2013 for Defect #25480
                        AND csl.status!='RECONCILED'                          --Added for defect#7656
                        AND ctc.bank_account_id = csh.bank_account_id
                        AND ctc.reconcile_flag = 'OI'
                        --AND TRUNC (csl.trx_date) = ld_sales_date
                        AND csl.amount = ln_sum_cash_check_deposits
                        AND rownum = 1;
                       lc_flag := 'Y';
                       lc_match_type := 'Multi Amount Match!';

            lp_print (' lc_match_type 1 :: '||lc_match_type, 'LOG'); --Defect #41450
                  EXCEPTION
                     WHEN OTHERS
                     THEN

						lp_print (' error Finding Multi Match :: '||SQLERRM, 'LOG'); --Defect #41450
                        NULL;
                  END;
               END IF;

            lp_print (' lc_flag 2 :: '||lc_flag, 'LOG'); --Defect #41450
               IF lc_flag = 'N' THEN
                  BEGIN
                     SELECT /*+ leading(csh) ordered use_nl(csh,csl,ctc) index(csl,CE_STATEMENT_LINES_N1) index(CSH,CE_STATEMENT_HEADERS_U2) */
							csl.amount
                           ,csl.statement_line_id
                           ,csl.trx_code_id
			   ,csl.trx_code                     ----Added for R12 retrofit by Aradhna Sharma on 19-Sep-2013 for Defect #25480
                           ,csl.bank_trx_number
                           ,csl.statement_header_id
                           ,csl.invoice_text
                           ,csl.bank_account_text
                           ,csl.customer_text
                           ,csl.trx_date
                           ,csh.statement_date
                       INTO ln_csl_deposit_amt
                           ,ln_csl_statement_line_id
                           ,ln_csl_trx_code_id
			   ,ln_csl_trx_code                 ----Added for R12 retrofit by Aradhna Sharma on 19-Sep-2013 for Defect #25480
                           ,lc_csl_bank_trx_number
                           ,ln_csl_statement_header_id
                           ,lc_csl_invoice_text
                           ,lc_csl_bank_account_text
                           ,lc_csl_customer_text
                           ,ld_csl_trx_date
                           ,ld_bank_statement_date
                       FROM --------ap_bank_accounts aba                      ----commented for R12 retrofit by Aradhna Sharma on 8-July-2013
		            ce_bank_accounts aba                              ----Added for R12 retrofit by Aradhna Sharma on 8-July-2013
		           ,ce_statement_headers csh
                           ,ce_statement_lines csl
                           ,ce_transaction_codes ctc
                      WHERE NVL (csl.attribute15, '~') = '~'
                        AND csl.statement_header_id = csh.statement_header_id
                        AND csh.bank_account_id = aba.bank_account_id
                        AND csh.bank_account_id = ln_bank_account_id
                    ---------    AND csl.trx_code_id = ctc.transaction_code_id          ----Commented for R12 retrofit by Aradhna Sharma on 16-Sep-2013
                 	AND csl.trx_code = ctc.trx_code                                   ----Added for R12 retrofit by Aradhna Sharma on 19-Sep-2013 for Defect #25480
                        AND csl.status!='RECONCILED'                          --Added for defect#7656
                        AND ctc.bank_account_id = csh.bank_account_id
                        AND ctc.reconcile_flag = 'OI'
                        AND ((SUBSTR (csl.invoice_text
                                     , LENGTH (csl.invoice_text) - 8
                                        , 9
                                      ) = lc_serial_loc || '2'
                              )
                              OR (SUBSTR (csl.invoice_text
                                     , LENGTH (csl.invoice_text) - 7
                                        , 8
                                         ) = lc_serial_loc
                                  )
                            )
                        AND (TRUNC (csl.trx_date) BETWEEN ld_sales_date
                                                 AND ld_sales_date + ln_days)
                        AND rownum = 1;
                        lc_flag := 'Y';
                        lc_match_type := 'Serial Number Match!';
/*****************R 1.2 CR 559 Fix****************Ends****************/

            lp_print (' lc_match_type 2 :: '||lc_match_type, 'LOG'); --Defect #41450
                     ln_deposit_bank_difference :=
                                            ln_csl_deposit_amt - ln_store_amount;

/*****************R 1.2 CR 559 Fix****************Starts****************/
 -- Commented Hard Coded Values and Added Translation
                     SELECT XFTV.TARGET_value2
                            ,XFTV.TARGET_value3
                       INTO lc_trans_seg_acct
                            ,lc_trans_seg_cost
                       FROM xx_fin_translatedefinition XFTD
                            ,xx_fin_translatevalues XFTV
                      WHERE XFTD.translate_id = XFTV.translate_id
                        AND XFTD.translation_name = gc_trans_name
                        AND XFTV.source_value2 = 'DIFFERENCE'
                        AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                        AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                        AND XFTV.enabled_flag = 'Y'
                        AND XFTD.enabled_flag = 'Y';
/*****************R 1.2 CR 559 Fix****************Ends****************/

            lp_print (' ln_deposit_bank_difference :: '||ln_deposit_bank_difference, 'LOG'); --Defect #41450
                     -- Create GL entries if there is an over/short condition
                     IF ln_deposit_bank_difference = 0
                     THEN
                        NULL;
                     --ELSIF ln_deposit_bank_difference > 0 --Defect 5310
                     ELSIF ln_deposit_bank_difference < 0
                     THEN
                        -- Bank deposit was lesser than store recorded deposit so
                        -- Debit store over/short manual acct for difference
/*****************R 1.2 CR 559 Fix****************Starts****************/
         -- Commented the below hardcorded values and added with translation
               --         lc_seg_acct := '79614000';        --  Over/Short Manual
               --         lc_seg_cost := '43002'; --Changed for the defect 15006--43001
                        lc_seg_acct := lc_trans_seg_acct;
                        lc_seg_cost := lc_trans_seg_cost;
/*****************R 1.2 CR 559 Fix****************Ends****************/
lp_print (' lc_aba_key :: '||lc_aba_key, 'LOG'); --Defect #41450
                        lc_seg_loc := lc_aba_key;
                        lc_je_line_dsc :=
                              lc_seg_loc
                           || '/'
                           || TO_CHAR (ld_sales_date, 'DD-MON-RR')
                           || '/'
                           || ' BK2 POS OvrShrt';
                        --lp_create_gl (ABS (ln_deposit_bank_difference), 0, ld_sales_date );
						lp_print ('Before lp_create_gl :: '||lc_error_loc, 'LOG'); --Defect #41450
                        lp_create_gl (ABS (ln_deposit_bank_difference)
                                    , 0
                                    , ld_sales_date
                                    , lc_je_line_dsc
                                     );
						lp_print (' After lp_create_gl 1 :: '||lc_error_loc, 'LOG'); --Defect #41450
                        -- and credit the store deposit cash account
                        lc_seg_acct := lc_store_cash_clearing;
                        lc_seg_cost := lc_store_seg_cost;
                        --lp_create_gl (0, ABS (ln_deposit_bank_difference), ld_sales_date);
                        lp_create_gl (0
                                    , ABS (ln_deposit_bank_difference)
                                    , ld_sales_date
                                    , lc_je_line_dsc
                                     );
                        lp_print('lc_seg_cost:'||lc_seg_cost,'BOTH');
						lp_print (' After lp_create_gl 2 :: '||lc_error_loc, 'LOG');--Defect #41450
                     ELSE
                        -- Bank deposit was greater than store recorded deposit so
                        -- Crebit store over/short manual acct for difference
/*****************R 1.2 CR 559 Fix****************Starts****************/
         -- Commented the below hardcorded values and added with translation
               --         lc_seg_acct := '79614000';        --  Over/Short Manual
              --          lc_seg_cost := '43002'; --Changed for the defect 15006--43001
                        lc_seg_acct := lc_trans_seg_acct;
                        lc_seg_cost := lc_trans_seg_cost;
/*****************R 1.2 CR 559 Fix****************Ends****************/
                        lc_seg_loc := lc_aba_key;
                        lc_je_line_dsc :=
                              lc_seg_loc
                           || '/'
                           || TO_CHAR (ld_sales_date, 'DD-MON-RR')
                           || '/'
                           || ' BK2 POS OvrShrt';
                        --lp_create_gl (0, ABS (ln_deposit_bank_difference),ld_sales_date);

						lp_print (' Before lp_create_gl 2 :: '||lc_error_loc, 'LOG');--Defect #41450
                        lp_create_gl (0
                                    , ABS (ln_deposit_bank_difference)
                                    , ld_sales_date
                                    , lc_je_line_dsc
                                     );
                        -- and debit the store deposit cash account
						lp_print (' After lp_create_gl 3 :: '||lc_error_loc, 'LOG');--Defect #41450
                        lc_seg_acct := lc_store_cash_clearing;
                        lc_seg_cost := lc_store_seg_cost;
                        --lp_create_gl (ABS (ln_deposit_bank_difference), 0, ld_sales_date);
                        lp_create_gl (ABS (ln_deposit_bank_difference)
                                    , 0
                                    , ld_sales_date
                                    , lc_je_line_dsc
                                     );
						lp_print (' After lp_create_gl 4 :: '||lc_error_loc, 'LOG');--Defect #41450
                        lp_print('lc_seg_cost:'||lc_seg_cost,'BOTH');
                     END IF;            --  End of there was a difference amount
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        RAISE le_exception_no_match;
                  END;                              --   MATCH OTHER TRANS TYPES
               END IF;          --  End of MIS trans type or other deposit type.

               /* -- -------------------------------------------
                  -- Now call the Create Open Interface
                  -- Procedure to create the record in the
                  -- XX_CE_999_INTERFACE custom table
                  -- for reconciliation and update the
                  -- CE.CE_STATEMENT_LINES table with necessary
                  -- values for matching.
                  -- ------------------------------------------- */
               lp_print (' create_open_interface :: ', 'LOG'); --Defect #41450
               create_open_interface
                           (
			    p_trx_code_id => ln_csl_trx_code_id
			  ,  p_trx_code => ln_csl_trx_code               ----Added for R12 retrofit by Aradhna Sharma on 19-Sep-2013 for Defect #25480
                          , p_bank_trx_number_org => lc_csl_bank_trx_number
                          , p_statement_header_id => ln_csl_statement_header_id
                          , p_statement_line_id => ln_csl_statement_line_id
                          , p_record_type => 'STORE_O/S'
                          , p_trx_date => ld_csl_trx_date
                          , p_amount => ln_csl_deposit_amt
                          , x_errbuf => lc_error_msg
                          , x_retcode => ln_retcode
                           );
               lp_print ('Passed to 999 Interface'||lc_error_loc, 'LOG');
               --  Update xx_ce_store_bank_deposits so this won't be processed again
               lc_error_loc := 'Update store_bank_deposits in ' || lc_match_type;
               lp_print (' lc_error_loc :: '||lc_error_loc, 'LOG'); --Defect #41450
               IF(lc_match_type = 'Multi Amount Match!') THEN
                  UPDATE xx_ce_store_bank_deposits pd
                     SET status_cd = 'B'
                   WHERE pd.loc_id = ln_loc_id
                     AND pd.deposit_type IN (SELECT XFTV.TARGET_value1
                                               FROM xx_fin_translatedefinition XFTD
                                                   ,xx_fin_translatevalues XFTV
                                              WHERE XFTD.translate_id = XFTV.translate_id
                                                AND XFTD.translation_name = gc_trans_name
                                                AND XFTV.source_value1 = 'MULTI_MATCH'
                                                AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                                                AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                                                AND XFTV.enabled_flag = 'Y'
                                                AND XFTD.enabled_flag = 'Y')
                     AND TRUNC (pd.sales_date) = ld_sales_date;
               ELSE
                  UPDATE xx_ce_store_bank_deposits
                     SET status_cd = 'B'
                   WHERE seq_nbr = ln_store_deposit_seq_nbr;
               END IF;

               lp_print (   LPAD (lc_aba_key, 9, ' ')
                         || '  '
                         || LPAD (ld_sales_date, 9, ' ')
                         || '  '
/*****************R 1.2 CR 559 Fix****************Starts****************/
 -- Formatted the output
                         || LPAD (ld_bank_statement_date, 14, ' ')
                         || '  '
                         || LPAD (ln_store_deposit_seq_nbr, 8, ' ')
                         || '  '
                    --     || '  Processed.'
                         || LPAD ('Processed',13, ' ')
                         || '  '
                         || lc_match_type
/*****************R 1.2 CR 559 Fix****************Ends****************/
                       , 'BOTH'
                        );
               --COMMIT;
               lc_error_loc := 'Store-Bank O/S Loop';
            END;                                 --  End of MATCH TO BAI DEPOSIT
         EXCEPTION
            WHEN le_exception_bad_store
            THEN
               lc_error_loc := lc_error_loc || ':lp_get_store_data';
               lp_print (lc_error_msg, 'BOTH');
               --lp_log_comn_error ('Store', lc_aba_key);
               lc_error_loc := 'Store-Bank O/S Loop';
               lp_print (   LPAD (ld_sales_date, 9, ' ')
                         || '  '
                         || LPAD (lc_aba_key, 9, ' ')
                         || '  '
                         || '               '
                         || LPAD (ln_store_deposit_seq_nbr, 9, ' ')
                         || '      Bank account setup incorrectly for store.'
                       , 'OUT'
                        );
               ROLLBACK TO lc_sdb_savepoint;
            WHEN le_exception_store_accounts
            THEN
               lc_error_loc := lc_error_loc || ':lp_get_store_data';
               lp_print (lc_error_msg, 'BOTH');
               --lp_log_comn_error ('Store', lc_aba_key);
               lc_error_loc := 'Store-Bank O/S Loop';
               lp_print (   LPAD (ld_sales_date, 9, ' ')
                         || '  '
                         || LPAD (lc_aba_key, 11, ' ')
                         || '  '
                         || '               '
                         || LPAD (ln_store_deposit_seq_nbr, 9, ' ')
                         || '      Multiple bank accounts set up for store.'
                       , 'OUT'
                        );
               ROLLBACK TO lc_sdb_savepoint;
            WHEN le_exception_no_match
            THEN                        --  That's OK since deposit may not have
                                        --  gotten to ce_statement_lines yet.
               lp_print ('Store bank deposit match not found.', 'LOG');
               lp_print ( LPAD (lc_aba_key, 9, ' ')
                         || '  '
                         ||LPAD (ld_sales_date, 9, ' ')
                         || '  '
                         || '               '
                         || LPAD (ln_store_deposit_seq_nbr, 9, ' ')
                         || '      Store bank deposit match not found'
                       , 'OUT'
                        );
               ROLLBACK TO lc_sdb_savepoint;
            WHEN OTHERS
            THEN
               lp_print (   LPAD (ld_sales_date, 9, ' ')
                         || '  '
                         || LPAD (lc_aba_key, 9, ' ')
                         || '  '
                         || '      Error processing Store bank deposit -'
                         || SQLCODE
                         || '-'
                         || SQLERRM
                         || '  Rolling back to savepoint '
                         || lc_sdb_savepoint
                       , 'LOG'
                        );
               ROLLBACK TO lc_sdb_savepoint;
         END;              -- End of process block for c_store_bank_deposit loop
      END LOOP;
      END LOOP;                             --  End of c_store_bank_deposit loop

     /* --  Process the change bank statement lines deposits  -- Commented as per the CR 559A--starts here--
      --  which processes Change Fund transactions and
      --  Cash Concentration sweep transactions
      lc_error_loc := 'Change/CC Deposits Loop';
      lp_print (' ', 'BOTH');
      lp_print (' ', 'BOTH');
      lp_print ('Process Change Fund/Cash Concentration Deposits', 'BOTH');
      lp_print (gc_line, 'BOTH');

      BEGIN
         --  First make sure all Master Store Concentration Account
         --  CCIDs are set up
         FOR i IN distinct_mscc_accounts
         LOOP
            ln_ccid :=
               fnd_flex_ext.get_ccid ('SQLGL'
                                         , 'GL#'
                                         , gn_coa_id
                                         , SYSDATE
                                         , i.attribute3
                                          );

            IF NVL (ln_ccid, 0) = 0
            THEN
               lc_error_msg := SUBSTR (fnd_flex_ext.GET_MESSAGE (), 1, 2500);
               lp_print (   'Account: '
                         || i.attribute3
                         || ' : '
                         || lc_error_msg
                         || '. Linked to the following bank accounts.'
                       , 'BOTH'
                        );
               lp_print (' ', 'BOTH');
               lp_print (   LPAD (' ', 12, ' ')
                         || RPAD ('Account #', 12, ' ')
                         || '  '
                         || 'Account Name'
                       , 'BOTH'
                        );
               lp_print (   LPAD (' ', 12, ' ')
                         || RPAD ('-', 12, '-')
                         || '  '
                         || RPAD ('-', 50, '-')
                       , 'BOTH'
                        );

               FOR j IN (SELECT bank_account_num, bank_account_name
                           FROM ap_bank_accounts
                          WHERE attribute3 = i.attribute3)
               LOOP
                  lp_print (   LPAD (' ', 12, ' ')
                            || LPAD (j.bank_account_num, 12, ' ')
                            || '  '
                            || RPAD (j.bank_account_name, 50, ' ')
                          , 'BOTH'
                           );
               END LOOP;
            END IF;
         END LOOP;
      EXCEPTION
         WHEN OTHERS
         THEN
            lp_print
               ('Error retrieving code combination for Master Store Concentration Accounts'
              , 'BOTH'
               );
      END;                       -- End of Mstr Store Conc Account verification.

      ln_rec_count := 0;

      FOR ba IN c_change_deposit_accounts
      LOOP                    --  Distinct Bank Account ID and it's GL Segments.
         ln_rec_count := ln_rec_count + 1;
         ln_det_count := 0;
         ln_bank_account_id := ba.bank_account_id;
         lc_currency_code := ba.currency_code;
         lc_loc_4 := SUBSTR (ba.segment4, 3, 4);

         IF ln_rec_count = 1
         THEN
            lp_print (   LPAD ('Bank Account #', 30, ' ')
                      || '  '
                      || RPAD ('Bank Account Name', 50, ' ')
                    , 'BOTH'
                     );
            lp_print (gc_line, 'BOTH');
         END IF;

         lp_print (   LPAD (ba.bank_account_num, 30, ' ')
                   || '  '
                   || RPAD (ba.bank_account_name, 80, ' ')
                 , 'BOTH'
                  );

         BEGIN                                -- Change transactions processing.
            lc_ch_dep_savepoint := 'Savepoint-' || ln_bank_account_id;
            lp_print ('Savepoint :' || lc_ch_dep_savepoint, 'LOG');

            FOR ctrans IN c_change_transactions
            LOOP
               ln_det_count := ln_det_count + 1;

               IF ln_det_count = 1
               THEN
                  lp_print (   LPAD (' ', 10, ' ')
                            || '  '
                            || LPAD ('Statement Number', 10, ' ')
                            || '  '
                            || LPAD ('Line#', 6, ' ')
                            || '  '
                            || LPAD ('Trx Date', 10, ' ')
                            || '  '
                            || LPAD ('Trx', 5, ' ')
                            || '  '
                            || LPAD ('Amount', 10, ' ')
                            || '  '
                            || RPAD ('Invoice text', 30, ' ')
                            || '  '
                          , 'BOTH'
                           );
                  lp_print (   LPAD (' ', 10, ' ')
                            || '  '
                            || LPAD ('-', 50, '-')
                            || '  '
                            || LPAD ('-', 6, '-')
                            || '  '
                            || LPAD ('-', 10, '-')
                            || '  '
                            || LPAD ('-', 5, '-')
                            || '  '
                            || LPAD ('-', 10, '-')
                            || '  '
                            || RPAD ('-', 30, '-')
                            || '  '
                          , 'BOTH'
                           );
               END IF;

               lp_print (   LPAD (' ', 10, ' ')
                         || '  '
                         || LPAD (ctrans.statement_number, 50, ' ')
                         || '  '
                         || LPAD (ctrans.line_number, 6, ' ')
                         || '  '
                         || LPAD (ctrans.trx_date, 10, ' ')
                         || '  '
                         || LPAD (ctrans.trx_code, 5, ' ')
                         || '  '
                         || LPAD (ctrans.amount, 10, ' ')
                         || '  '
                         || RPAD (ctrans.invoice_text, 30, ' ')
                       , 'BOTH'
                        );
               -- Determine trans code and then create GL
               lc_seg_co := ba.segment1;
               lc_seg_cost := ba.segment2;
               lc_seg_acct := ba.segment3;
               lc_seg_loc := ba.segment4;
               lc_seg_ic := ba.segment5;
               lc_seg_lob := ba.segment6;
               lc_seg_fut := ba.segment7;
               --CR 423 - Process only Trx Code 575 (Ignore 366/639/666).
               -- Defect 11020 - Treat 577 same as 575
--               IF ctrans.trx_code IN ('575', '577')
--               THEN
                  --  575 sweep transactions.
                  --  credit the store deposit cash clearing account
               lc_seg_acct := ba.segment3;
               lc_seg_loc := ba.segment4;
               lc_je_line_dsc :=
                     lc_seg_loc
                  || '/'
                  || TO_CHAR (ctrans.trx_date, 'DD-MON-RR')
                  || '/ Trx Code '
                  || ctrans.trx_code
                  || ' Dep Conc';
               lp_create_gl (0, ctrans.amount, ctrans.trx_date, lc_je_line_dsc);
               -- and Debit the master store clearing account
               lc_seg_co := ba.conc1;
               lc_seg_cost := ba.conc2;
               lc_seg_acct := ba.conc3;
               lc_seg_loc := ba.conc4;
               lc_seg_ic := ba.conc5;
               lc_seg_lob := ba.conc6;
               lc_seg_fut := ba.conc7;
               lc_je_line_dsc :=
                     lc_seg_loc
                  || '/'
                  || TO_CHAR (ctrans.trx_date, 'DD-MON-RR')
                  || '/ Trx Code '
                  || ctrans.trx_code
                  || ' Dep Conc';
               lp_create_gl (ctrans.amount, 0, ctrans.trx_date, lc_je_line_dsc); */ --Commented for CR 559A--ends here--

--               END IF;

               /*IF ctrans.trx_code = '366'
               THEN
                  -- Debit the store deposit cash clearing account
                  lc_seg_acct := ba.segment3;
                  lc_seg_loc := ba.segment4;
                  lc_je_line_dsc := lc_seg_loc
                                    || '/'
                                    || TO_CHAR(ctrans.trx_date, 'DD-MON-RR')
                                    || '/ Trx Code '
                                    || ctrans.trx_code
                                    || ' Chg Fund Dep';
                  --lp_create_gl (ctrans.amount, 0, ba.statement_date);
                  lp_create_gl(ctrans.amount, 0, ctrans.trx_date
                             , lc_je_line_dsc);
                  -- and credit the change fund clearing account
                  lc_seg_acct := '10199601';
                  lc_seg_loc := ba.segment4;
                  lc_je_line_dsc := lc_seg_loc
                                    || '/'
                                    || TO_CHAR(ctrans.trx_date, 'DD-MON-RR')
                                    || '/ Trx Code '
                                    || ctrans.trx_code
                                    || '/ Chg Fund Dep';
                  --lp_create_gl (0, ctrans.amount, ba.statement_date);
                  lp_create_gl(0, ctrans.amount, ctrans.trx_date
                             , lc_je_line_dsc);
               ELSIF ctrans.trx_code IN('666', '629')
               THEN                    -- this is a 666 or 629 transaction so
                                       -- Debit the change fund clearing account
                  lc_seg_acct := '10199601';
                  lc_seg_loc := ba.segment4;
                  --lp_create_gl (ctrans.amount, 0, ba.statement_date);
                  lc_je_line_dsc := lc_seg_loc
                                    || '/'
                                    || TO_CHAR(ctrans.trx_date, 'DD-MON-RR')
                                    || '/ Trx Code '
                                    || ctrans.trx_code
                                    || ' Chg Fund Dep';
                  lp_create_gl(ctrans.amount, 0, ctrans.trx_date
                             , lc_je_line_dsc);
                  -- and credit the store deposit cash clearing account
                  lc_seg_acct := ba.segment3;
                  lc_seg_loc := ba.segment4;
                  --lp_create_gl (0, ctrans.amount, ba.statement_date);
                  lc_je_line_dsc := lc_seg_loc
                                    || '/'
                                    || TO_CHAR(ctrans.trx_date, 'DD-MON-RR')
                                    || '/ Trx Code '
                                    || ctrans.trx_code
                                    || ' Chg Fund Dep';
                  lp_create_gl(0, ctrans.amount, ctrans.trx_date
                             , lc_je_line_dsc);
               ELSIF ctrans.trx_code = '575'
               THEN
                  --  because of the cursor select this is a 575 sweep trans so
                  --  credit the store deposit cash clearing account
                  lc_seg_acct := ba.segment3;
                  lc_seg_loc := ba.segment4;
                  --lp_create_gl (0, ctrans.amount, ba.statement_date);
                  lc_je_line_dsc := lc_seg_loc
                                    || '/'
                                    || TO_CHAR(ctrans.trx_date, 'DD-MON-RR')
                                    || '/ Trx Code '
                                    || ctrans.trx_code
                                    || ' Dep Conc';
                  lp_create_gl(0, ctrans.amount, ctrans.trx_date
                             , lc_je_line_dsc);
                  -- and Debit the master store clearing account
                  lc_seg_co := ba.conc1;
                  lc_seg_cost := ba.conc2;
                  lc_seg_acct := ba.conc3;
                  lc_seg_loc := ba.conc4;
                  lc_seg_ic := ba.conc5;
                  lc_seg_lob := ba.conc6;
                  lc_seg_fut := ba.conc7;
                  --lp_create_gl (ctrans.amount, 0, ba.statement_date);
                  lc_je_line_dsc := lc_seg_loc
                                    || '/'
                                    || TO_CHAR(ctrans.trx_date, 'DD-MON-RR')
                                    || '/ Trx Code '
                                    || ctrans.trx_code
                                    || ' Dep Conc';
                  lp_create_gl(ctrans.amount, 0, ctrans.trx_date
                             , lc_je_line_dsc);
               ELSE
                  -- For Change deposits where transactions coded incorrectly by bank,
                  -- but he first 2 digits of Invoice Text = 33, treat same as '366'.
                   -- Debit the store deposit cash clearing account
                  lc_seg_co := ba.segment1;
                  lc_seg_cost := ba.segment2;
                  lc_seg_acct := ba.segment3;
                  lc_seg_loc := ba.segment4;
                  lc_seg_ic := ba.segment5;
                  lc_seg_lob := ba.segment6;
                  lc_seg_fut := ba.segment7;
                  --lp_create_gl (ctrans.amount, 0, ba.statement_date);
                  lc_je_line_dsc := lc_seg_loc
                                    || '/'
                                    || TO_CHAR(ctrans.trx_date, 'DD-MON-RR')
                                    || '/ Trx Code '
                                    || ctrans.trx_code
                                    || ' Chg Fund Dep';
                  lp_create_gl(ctrans.amount, 0, ctrans.trx_date
                             , lc_je_line_dsc);
                  -- and credit the change fund clearing account
                  lc_seg_acct := '10199601';
                  lc_seg_loc := ba.segment4;
                  --lp_create_gl (0, ctrans.amount, ba.statement_date);
                  lc_je_line_dsc := lc_seg_loc
                                    || '/'
                                    || TO_CHAR(ctrans.trx_date, 'DD-MON-RR')
                                    || '/ Trx Code '
                                    || ctrans.trx_code
                                    || ' Chg Fund Dep';
                  lp_create_gl(0, ctrans.amount, ctrans.trx_date
                             , lc_je_line_dsc);
               END IF;
               */
               --  Now update the deposit line to keep from doing this again
              /* UPDATE ce_statement_lines   -- Commented  for the CR 559A--starts here--
                  SET attribute15 = 'PROC-E1318-YES'
                WHERE statement_line_id = ctrans.statement_line_id;
            END LOOP;         --  End of Determine trans code and then create GL
         EXCEPTION
            WHEN le_exception_gl_call
            THEN
               lp_print (   LPAD (' ', 10, ' ')
                         || '  '
                         || 'Error processing Change Transaction. '
                       , 'BOTH'
                        );
               ROLLBACK TO SAVEPOINT lc_ch_dep_savepoint;
            WHEN OTHERS
            THEN
               lp_print (   LPAD (' ', 10, ' ')
                         || '  '
                         || 'Error processing Change Transaction. '
                       , 'BOTH'
                        );
               ROLLBACK TO SAVEPOINT lc_ch_dep_savepoint;
         END;                                        -- Change transactions end;
      END LOOP;    --  End of Distinct Bank Account ID and it's GL Segments Loop

      lp_print (' ', 'BOTH');
      lp_print (' ', 'BOTH');
      lp_print (   'Summary of Journal Entries created with Group ID:'
                || ln_group_id
              , 'BOTH'
               );
      lp_print (gc_line, 'BOTH');
      lp_print (' ', 'BOTH');
      ln_rec_count := 0;

      FOR i IN rpt_gl
      LOOP
         ln_rec_count := ln_rec_count + 1;

         IF ln_rec_count = 1
         THEN
            lp_print (   LPAD ('Count', 8, ' ')
                      || '  '
                      || RPAD ('Account', 42, ' ')
                      || '  '
                      || LPAD ('Debit  ', 15, ' ')
                      || '  '
                      || LPAD ('Credit  ', 15, ' ')
                    , 'BOTH'
                     );
            lp_print (   RPAD ('-', 8, '-')
                      || '  '
                      || RPAD ('-', 42, '-')
                      || '  '
                      || LPAD ('-', 15, '-')
                      || '  '
                      || LPAD ('-', 15, '-')
                    , 'BOTH'
                     );
         END IF;

         lc_print_line :=
            (   LPAD (i.gl_cnt, 8, ' ')
             || '  '
             || i.segment1
             || '.'
             || i.segment2
             || '.'
             || i.segment3
             || '.'
             || i.segment4
             || '.'
             || i.segment5
             || '.'
             || i.segment6
             || LPAD (TO_CHAR (i.gl_dr, '0000000.99'), 15, ' ')
             || LPAD (TO_CHAR (i.gl_cr, '0000000.99'), 30, ' ')
            );
         lp_print (lc_print_line, 'BOTH');
      END LOOP;

      IF ln_rec_count = 0
      THEN
         lp_print (' - - - - - No Journal Entries Created - - - - -', 'BOTH');
      END IF;  */   -- Commented  for the CR 559A--ends here--

      lp_print (' ', 'LOG');
      x_retcode := ln_normal;
      lp_print ('Finished ' || TO_CHAR (SYSDATE, 'dd-mon-yyyy hh:mi:ss'), 'LOG');
   EXCEPTION
            /* -- ------------------------------------------------------
               -- Print errors to the log and call the Custom Common
               -- Error Handling procedure
               -- ------------------------------------------------------ */
      --      WHEN le_exception_trx_code
      --      THEN
      --         ROLLBACK;                          -- Logging handled in local proc.
      --      WHEN le_exception_999
      --      THEN
      --         ROLLBACK;                          -- Logging handled in local proc.
      WHEN OTHERS
      THEN
         ROLLBACK;
         x_retcode := ln_error;
         lc_error_loc := lc_error_loc || ' - Main procedure exception';
         lp_print (lc_error_msg, 'BOTH');
         lp_log_comn_error ('STORE OVER/SHORT - CC', 'Unresolved');
   END store_os_cc_main;
END xx_ce_store_os_cc_pkg;
/