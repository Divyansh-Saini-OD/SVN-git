create or replace PACKAGE BODY XX_CE_CUST_JE_LINES_CREATE_PKG
AS
-- +=============================================================================+
-- |                  Office Depot - Project Simplify                            |
-- |                    Office Depot Organization                                |
-- +=============================================================================+
-- | Name  : XX_CE_CUST_JE_LINES_CREATE_PKG                                      |
-- | Description      :  This Package is created for custom JE creation          |
-- |                     extension that excludes certain BAI2                    |
-- |                     Transaction codes on the bank statement lines           |
-- |                     from standard JE creation so they are not sent          |
-- |                     through the standard JE and reconciliation              |
-- |                     process, enabling processing by the                     |
-- |                     other CE custom extensions.                             |
-- |                                                                             |
-- |                                                                             |
-- | RICE#            : E2027                                                    |
-- | Main ITG Package :                                                          |
-- |                                                                             |
-- |Change Record:                                                               |
-- |===============                                                              |
-- |Version  Date         Author            Remarks                              |
-- |=======  ==========   =============     =====================================|
-- |DRAFT 1A 09-DEC-2008  Pradeep Krishnan  Initial draft version                |
-- |1.1      12-JAN-2009  Pradeep Krishnan  Updated the code for the             |
-- |                                        defect 12790.                        |
-- |1.2      04-FEB-2009  Pradeep Krishnan  Updated the code for the             |
-- |                                        defect 12914.                        |
-- |1.3      11-OCT-2012  Abdul Khan        QC 20234 - Added condition           |
-- |                                        so that Reconciled  lines            |
-- |                                        doesnt get picked by E2027           |
-- |1.4      15-JUL-2013  Arun Pandian	    Retrofitted with R12                 |
-- |1.5      18-MAY-2016  Avinash Baddam    Changes for defect#37859             |
-- |1.5      18-MAY-2016  Avinash Baddam    Changes for defect#37859             |
-- |2.0      07-Apr-2020  Amit Kumar    	Changes for E1319		             |
-- |2.1 	 25-Sep-2020  Manjush D		    Changes for NAIT-149495              |
-- |2.2      30-Nov-2020  Pratik Gadia		Changes for NAIT-140412              |
-- |2.3      27-Apr-2021  Pratik Gadia	    Changes for NAIT-175362              |
-- |2.3      14-May-2021  Ankit Jaiswal	    Changes for NAIT-138934 Wells Fargo  |
-- |                                        Bank changes for Transaction Code    |
-- +=============================================================================+
---Declaring all variables
  ln_cash_bank_account_id    ce_statement_headers.bank_account_id%TYPE;
  ln_statement_number        ce_statement_headers.statement_number%TYPE;
  ln_header_id               ce_statement_lines.statement_header_id%TYPE;
  ld_statement_date          ce_statement_headers.statement_date%TYPE;
  ln_statement_line_number   ce_statement_lines.line_number%TYPE;
  ln_statement_line_id       ce_statement_lines.statement_line_id%TYPE;
  ld_trx_date                ce_statement_lines.trx_date%TYPE;
  lc_trx_type                ce_statement_lines.trx_type%TYPE;
  ln_amount                  ce_statement_lines.amount%TYPE;
  lc_invoice_text            ce_statement_lines.invoice_text%TYPE;
  lc_trx_code                ce_transaction_codes.trx_code%TYPE;
  ln_user_id                 NUMBER := fnd_global.user_id;
  ln_group_id                NUMBER;
  ld_gl_date                 VARCHAR2(20);
  ln_asset_bank_account_id   ce_bank_accounts.bank_account_id%TYPE;
  lc_bank_acct_num           ce_bank_accounts.bank_account_num%TYPE;
  lc_bank_account            ce_bank_accounts.bank_account_num%TYPE;
  lc_currency_code           ce_bank_accounts.currency_code%TYPE;
  ln_sob_id                  hr_operating_units.set_of_books_id%TYPE;
  ln_org_id                  ce_bank_acct_uses.org_id%TYPE;
  lc_bank_name               hz_organization_profiles.organization_name%TYPE;
  lpv_description            VARCHAR2(240);
  lc_output_msg              VARCHAR2(240);
  lc_output_msg1             VARCHAR2(240);
  lc_bank_branch	     hz_parties.party_name%TYPE;
  lc_ba_segment1             gl_code_combinations.segment1%TYPE;
  lc_ba_segment2             gl_code_combinations.segment2%TYPE;
  lc_ba_segment3             gl_code_combinations.segment3%TYPE;
  lc_ba_segment4             gl_code_combinations.segment4%TYPE;
  lc_ba_segment5             gl_code_combinations.segment5%TYPE;
  lc_ba_segment6             gl_code_combinations.segment6%TYPE;
  lc_ba_segment7             gl_code_combinations.segment7%TYPE;
  lc_segment1                gl_code_combinations.segment1%TYPE;
  lc_segment2                gl_code_combinations.segment2%TYPE;
  lc_segment3                gl_code_combinations.segment3%TYPE;
  lc_segment4                gl_code_combinations.segment4%TYPE;
  lc_segment5                gl_code_combinations.segment5%TYPE;
  lc_segment6                gl_code_combinations.segment6%TYPE;
  lc_segment7                gl_code_combinations.segment7%TYPE;
  lc_cr_company              gl_code_combinations.segment1%TYPE;
  lc_cr_cost_center          gl_code_combinations.segment2%TYPE;
  lc_cr_account              gl_code_combinations.segment3%TYPE;
  lc_cr_location             gl_code_combinations.segment4%TYPE;
  lc_cr_intercompany         gl_code_combinations.segment5%TYPE;
  lc_cr_channel              gl_code_combinations.segment6%TYPE;
  lc_cr_future               gl_code_combinations.segment7%TYPE;
  lc_dr_company              gl_code_combinations.segment1%TYPE;
  lc_dr_cost_center          gl_code_combinations.segment2%TYPE;
  lc_dr_account              gl_code_combinations.segment3%TYPE;
  lc_dr_location             gl_code_combinations.segment4%TYPE;
  lc_dr_intercompany         gl_code_combinations.segment5%TYPE;
  lc_dr_channel              gl_code_combinations.segment6%TYPE;
  lc_dr_future               gl_code_combinations.segment7%TYPE;
  ln_cnt                     NUMBER := 0;
  ln_cnt1                    NUMBER := 0;
  ln_cnt2                    NUMBER := 0;
  EX_ERROR                   EXCEPTION;
  EX_ERROR_WF                EXCEPTION;
  ln_WF                      NUMBER := NULL; --NAIT-175362 
  
-- +===================================================================+
-- | Name  : CREATE_GL_INTRF_WF_LINE                             	   |
-- | Description      : This Procedure is used to insert  GL Journal for|
-- |                    Wells Fargo Statement entry line into      		|
-- |                    the XX_GL_INTERFACE_NA_STG table.              |
-- |                                                                   |
-- | Parameters :p_bank_branch_id                                      |
-- |             p_bank_account_id                                     |
-- |             p_statement_number_from                               |
-- |             p_statement_number_to                                 |
-- |             p_statement_date_from                                 |
-- |             p_statement_date_to                                   |
-- |             p_gl_date                                             |
-- |                                                                   |
-- +===================================================================+
PROCEDURE CREATE_GL_INTRF_WF_LINE (
		   p_bank_branch_id        IN NUMBER
          ,p_bank_account_id       IN NUMBER
          ,p_statement_number_from IN VARCHAR2
          ,p_statement_number_to   IN VARCHAR2
          ,p_statement_date_from   IN VARCHAR2
          ,p_statement_date_to     IN VARCHAR2
          ,p_gl_date               IN VARCHAR2
          )
IS
  ------------------------------------------------------------------
  -- Cursor to get all the statement lines based on the parameters
  -- which has a cash account value in the Attribute10 field of the
  -- CE_STATEMENT_LINES table and which is not yet processed
  ------------------------------------------------------------------
  CURSOR lcu_gl_line_wf
  IS
		SELECT
		/*+ leading(csh) ordered use_nl(csh,csl,ctc) index(csl,CE_STATEMENT_LINES_N1) use_merge(ctc) full(ctc)*/
            CTC.bank_account_id
			,csh.bank_Account_id master_bank_acct_id   --Added for ver#2.1
           ,CSH.statement_number
           ,CSH.statement_date
           ,CSL.line_number
           ,CSL.statement_line_id
           ,CSL.trx_date
           ,CSL.trx_type
           ,CSL.amount
           ,CSL.statement_header_id
           ,CSL.invoice_text
           ,CTC.trx_code
           ,CBA.currency_code
           ,GCC.segment1
           ,GCC.segment2
           ,GCC.segment3
           ,GCC.segment4
           ,GCC.segment5
           ,GCC.segment6
           ,GCC.segment7
		FROM ce_statement_headers csh
		  , ce_statement_lines csl
		  , ce_transaction_codes ctc
		  , ce_bank_accounts cba
		  ,gl_code_combinations gcc
		  ,Hz_parties hp
		WHERE csl.attribute15              IS NULL
		AND csl.statement_header_id        = csh.statement_header_id
		AND csh.bank_account_id            = NVL(p_bank_account_id,CSH.bank_account_id)
		AND   CSH.statement_number BETWEEN NVL(p_statement_number_from,CSH.statement_number)
                                    AND NVL(p_statement_number_to,CSH.statement_number)
        AND   fnd_date.canonical_to_date(CSH.statement_date) BETWEEN NVL(fnd_date.canonical_to_date(p_statement_date_from),fnd_date.canonical_to_date(CSH.statement_date))
                                                              AND NVL(fnd_date.canonical_to_date(p_statement_date_to),fnd_date.canonical_to_date(CSH.statement_date))
		AND lpad(SUBSTR (cba.agency_location_code, 3), 9,'0') = SUBSTR (csl.CUSTOMER_TEXT,3)
		AND   NVL(CSL.attribute2,'N')   <> 'PROC-E2027-YES'
		AND csl.status!                    ='RECONCILED'
		AND SUBSTR (csl.CUSTOMER_TEXT,3) =lpad(gcc.segment4, 9,'0')
		AND gcc.code_combination_id   = CTC.attribute10
		AND NVL (cba.end_date, SYSDATE  + 1) > TRUNC (SYSDATE)
		AND csl.trx_code                   = ctc.trx_code
		and ctc.bank_Account_id			   =cba.bank_Account_id
		AND   CTC.attribute10 IS NOT NULL
		AND hp.party_id                      = cba.bank_id
		--AND hp.party_name                  ='WELLS FARGO BANK'  --Commented for NAIT-140412
		--<START> Added for NAIT-140412			
		AND hp.party_name IN
					(SELECT upper(XFTV.source_value2)
					 FROM xx_fin_translatedefinition XFTD,xx_fin_translatevalues XFTV
					 WHERE XFTD.translate_id = XFTV.translate_id
					 AND XFTD.translation_name = 'XX_CM_E1319_STORE_OS_CC'
					 AND XFTV.source_value1 = 'BANK'
					 AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
					 AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
					 AND XFTV.enabled_flag = 'Y'
					 AND XFTD.enabled_flag = 'Y')
		--<END> Added for NAIT-140412	
		AND hp.party_type                    ='ORGANIZATION'
		AND regexp_replace(cba.bank_account_name, '[^[:digit:]]', '') IS NOT NULL
		AND gcc.segment4                                               = SUBSTR (cba.agency_location_code, 3)
		--<START> Added for NAIT-138934
		AND CTC.TRX_CODE NOT IN (SELECT xftv.target_value1
								 FROM xx_fin_translatedefinition XFTD,xx_fin_translatevalues XFTV
								 WHERE XFTD.translate_id = XFTV.translate_id
								 AND XFTD.translation_name = 'XX_CM_E1319_STORE_OS_CC'
								 AND XFTV.source_value1 = 'BSTMT_TRX_CODE'
								 AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
								 AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
								 AND XFTV.enabled_flag = 'Y'
								 AND XFTD.enabled_flag = 'Y')   
		UNION
		 SELECT 
		/*+ leading(csh) ordered use_nl(csh,csl,ctc) index(csl,CE_STATEMENT_LINES_N1) use_merge(ctc) full(ctc)*/
            CTC.bank_account_id
			,csh.bank_Account_id master_bank_acct_id   --Added for ver#2.1
           ,CSH.statement_number
           ,CSH.statement_date
           ,CSL.line_number
           ,CSL.statement_line_id
           ,CSL.trx_date
           ,CSL.trx_type
           ,CSL.amount
           ,CSL.statement_header_id
           ,CSL.invoice_text
           ,CTC.trx_code
           ,CBA.currency_code
           ,GCC.segment1
           ,GCC.segment2
           ,GCC.segment3
           ,GCC.segment4
           ,GCC.segment5
           ,GCC.segment6
           ,GCC.segment7
		FROM ce_statement_headers csh
		  , ce_statement_lines csl
		  , ce_transaction_codes ctc
		  , ce_bank_accounts cba
		  ,gl_code_combinations gcc
		  ,Hz_parties hp
		  ,CE_JE_MAPPINGS JEM 
		WHERE csl.attribute15              IS NULL
		AND csl.statement_header_id        = csh.statement_header_id
		AND csh.bank_account_id            = NVL(p_bank_account_id,CSH.bank_account_id)
		AND   CSH.statement_number BETWEEN NVL(p_statement_number_from,CSH.statement_number)
                                    AND NVL(p_statement_number_to,CSH.statement_number)
        AND   fnd_date.canonical_to_date(CSH.statement_date) BETWEEN NVL(fnd_date.canonical_to_date(p_statement_date_from),fnd_date.canonical_to_date(CSH.statement_date))
                                                              AND NVL(fnd_date.canonical_to_date(p_statement_date_to),fnd_date.canonical_to_date(CSH.statement_date))
		AND lpad(SUBSTR (cba.agency_location_code, 3), 9,'0') = SUBSTR (csl.CUSTOMER_TEXT,3)
		AND   NVL(CSL.attribute2,'N')   <> 'PROC-E2027-YES'
		AND csl.status!                    ='RECONCILED'
		AND SUBSTR (csl.CUSTOMER_TEXT,3) =lpad(gcc.segment4, 9,'0')
		--AND gcc.code_combination_id   = CTC.attribute10  
		AND jem.GL_ACCOUNT_CCID = gcc.code_combination_id  
		AND JEM.TRX_CODE_ID                      = CTC.TRANSACTION_CODE_ID  
		AND NVL (cba.end_date, SYSDATE  + 1) > TRUNC (SYSDATE)
		AND csl.trx_code                   = ctc.trx_code
		and ctc.bank_Account_id			   =cba.bank_Account_id
		--AND   CTC.attribute10 IS NOT NULL  
		AND hp.party_id                      = cba.bank_id	
		AND hp.party_name IN
					(SELECT upper(XFTV.source_value2)
					 FROM xx_fin_translatedefinition XFTD,xx_fin_translatevalues XFTV
					 WHERE XFTD.translate_id = XFTV.translate_id
					 AND XFTD.translation_name = 'XX_CM_E1319_STORE_OS_CC'
					 AND XFTV.source_value1 = 'BANK'
					 AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
					 AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
					 AND XFTV.enabled_flag = 'Y'
					 AND XFTD.enabled_flag = 'Y')
		AND hp.party_type                    ='ORGANIZATION'
		AND regexp_replace(cba.bank_account_name, '[^[:digit:]]', '') IS NOT NULL
		AND ctc.trx_code IN (SELECT xftv.target_value1
							FROM xx_fin_translatedefinition XFTD,xx_fin_translatevalues XFTV
							WHERE XFTD.translate_id = XFTV.translate_id
							AND XFTD.translation_name = 'XX_CM_E1319_STORE_OS_CC'
							AND XFTV.source_value1 = 'BSTMT_TRX_CODE'
							AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
							AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
							AND XFTV.enabled_flag = 'Y'
							AND XFTD.enabled_flag = 'Y') 
		AND gcc.segment4 = SUBSTR (cba.agency_location_code, 3);
		--<END> Added for NAIT-138934 Wells Fargo Bank Transaction Code Change
	ln_master_bank_acct_id  NUMBER; --Added Ver#2.1
	ln_is_je_trx_code VARCHAR2(50); --Added for NAIT-138934	 

	BEGIN
	    LN_master_bank_acct_id :=NULL; --Added Ver#2.1
		ln_cash_bank_account_id    :=NULL;
	  ln_statement_number        :=NULL;
	  ln_header_id               :=NULL;
	  ld_statement_date          :=NULL;
	  ln_statement_line_number   :=NULL;
	  ln_statement_line_id       :=NULL;
	  ld_trx_date                :=NULL;
	  lc_trx_type                :=NULL;
	  ln_amount                  :=NULL;
	  lc_invoice_text            :=NULL;
	  lc_trx_code                :=NULL;
	  ln_group_id                :=NULL;
	  ld_gl_date                 :=NULL;
	  ln_asset_bank_account_id   :=NULL;
	  lc_bank_acct_num           :=NULL;
	  lc_bank_account            :=NULL;
	  lc_currency_code           :=NULL;
	  ln_sob_id                  :=NULL;
	  ln_org_id                  :=NULL;
	  lc_bank_name               :=NULL;
	  lpv_description            :=NULL;
	  lc_output_msg              :=NULL;
	  lc_output_msg1             :=NULL;
	  lc_bank_branch	         :=NULL;
	  lc_ba_segment1             :=NULL;
	  lc_ba_segment2             :=NULL;
	  lc_ba_segment3             :=NULL;
	  lc_ba_segment4             :=NULL;
	  lc_ba_segment5             :=NULL;
	  lc_ba_segment6             :=NULL;
	  lc_ba_segment7             :=NULL;
	  lc_segment1                :=NULL;
	  lc_segment2                :=NULL;
	  lc_segment3                :=NULL;
	  lc_segment4                :=NULL;
	  lc_segment5                :=NULL;
	  lc_segment6                :=NULL;
	  lc_segment7                :=NULL;
	  lc_cr_company              :=NULL;
	  lc_cr_cost_center          :=NULL;
	  lc_cr_account              :=NULL;
	  lc_cr_location             :=NULL;
	  lc_cr_intercompany         :=NULL;
	  lc_cr_channel              :=NULL;
	  lc_cr_future               :=NULL;
	  lc_dr_company              :=NULL;
	  lc_dr_cost_center          :=NULL;
	  lc_dr_account              :=NULL;
	  lc_dr_location             :=NULL;
	  lc_dr_intercompany         :=NULL;
	  lc_dr_channel              :=NULL;
	  lc_dr_future               :=NULL;
	  ln_cnt                     :=0;
	  ln_cnt1                    :=0;
	  ln_cnt2                    :=0;

		FND_FILE.PUT_LINE(FND_FILE.LOG,'CREATE_GL_INTRF_WF_LINE: p_bank_branch_id			' ||p_bank_branch_id);
		FND_FILE.PUT_LINE(FND_FILE.LOG,'CREATE_GL_INTRF_WF_LINE: p_bank_account_id			' ||p_bank_account_id);
		FND_FILE.PUT_LINE(FND_FILE.LOG,'CREATE_GL_INTRF_WF_LINE: p_statement_number_from	' ||p_statement_number_from);
		FND_FILE.PUT_LINE(FND_FILE.LOG,'CREATE_GL_INTRF_WF_LINE: p_statement_number_to		' ||p_statement_number_to);
		FND_FILE.PUT_LINE(FND_FILE.LOG,'CREATE_GL_INTRF_WF_LINE: p_statement_date_from		' ||p_statement_date_from);
		FND_FILE.PUT_LINE(FND_FILE.LOG,'CREATE_GL_INTRF_WF_LINE: p_statement_date_to		' ||p_statement_date_to);
		FND_FILE.PUT_LINE(FND_FILE.LOG,'CREATE_GL_INTRF_WF_LINE: p_gl_date					' ||p_gl_date);


		IF p_bank_branch_id IS NOT NULL THEN
		BEGIN
			SELECT bank_branch_name, bank_name
			  INTO lc_bank_branch, lc_bank_name
			  FROM ce_bank_branches_v
			 WHERE branch_party_id = p_bank_branch_id;
		Exception
			 When Others Then
			 FND_FILE.PUT_LINE(FND_FILE.LOG,'CREATE_GL_INTRF_WF_LINE: Error in fetching the bank branch name.');
		END;
		END IF;

		IF p_bank_account_id IS NOT NULL
		THEN
		BEGIN
			SELECT bank_account_num
			  INTO lc_bank_account
			  FROM ce_bank_accounts
			 WHERE bank_account_id = p_bank_account_id;
		Exception
			 When Others Then
			 FND_FILE.PUT_LINE(FND_FILE.LOG,'CREATE_GL_INTRF_WF_LINE: Error in fetching the bank account number.');
		END;
		END IF;
		
		FND_FILE.PUT_LINE(FND_FILE.Output,'_________________________________________________________________________________________________________________________');
		FND_FILE.PUT_LINE(FND_FILE.Output,'');
		FND_FILE.PUT_LINE(FND_FILE.Output,'=========================================================================================================================');
		FND_FILE.PUT_LINE(FND_FILE.Output,'');
		FND_FILE.PUT_LINE(FND_FILE.Output,'                         Custom Journal Entry Creation Execution Report  for Wells Fargo Store Accounts                                                   Report Date :  ' ||to_char(sysdate,'DD-MON-YY HH:MM'));
		FND_FILE.PUT_LINE(FND_FILE.Output,'                                                                                                                                                                  ');
		FND_FILE.PUT_LINE(FND_FILE.Output,'                                                                                                                                                                  ');
		FND_FILE.PUT_LINE(FND_FILE.Output,'                                                                                                                                                                  ');
		FND_FILE.PUT_LINE(FND_FILE.Output,' Bank Name             :' || lc_bank_name);
		FND_FILE.PUT_LINE(FND_FILE.Output,' Bank Branch Name      :' || lc_bank_branch);
		FND_FILE.PUT_LINE(FND_FILE.Output,' Bank Account Number   :' || lc_bank_account);
		FND_FILE.PUT_LINE(FND_FILE.Output,' Statement Number From :' || p_statement_number_from);
		FND_FILE.PUT_LINE(FND_FILE.Output,' Statement Number to   :' || p_statement_number_to);
		FND_FILE.PUT_LINE(FND_FILE.Output,' Statement Date From   :' || p_statement_date_from);
		FND_FILE.PUT_LINE(FND_FILE.Output,' Statement Date To     :' || p_statement_date_to);
		FND_FILE.PUT_LINE(FND_FILE.Output,' GL Date               :' || p_gl_date);
		FND_FILE.PUT_LINE(FND_FILE.Output,'                                                                                                                                                                  ');
		FND_FILE.PUT_LINE(FND_FILE.Output,'                                                                                                                                                                  ');
		FND_FILE.PUT_LINE(FND_FILE.Output,'Bank Acc #               Statement #          Currency    Statement Date    Statement Line    TRX Code   GL Acct String                                             DR $ Amount                CR $ Amount');
		FND_FILE.PUT_LINE(FND_FILE.Output,'----------               -----------          --------    --------------    --------------    --------   --------------                                             ------------               -----------');

   BEGIN


		BEGIN
			 SELECT gl_interface_control_s.NEXTVAL
			 INTO   ln_group_id
			 FROM   SYS.DUAL;
		EXCEPTION
		  WHEN OTHERS THEN
			FND_FILE.PUT_LINE(FND_FILE.LOG,'CREATE_GL_INTRF_WF_LINE: Error in GL Interface sequence.');
		END;


	OPEN lcu_gl_line_wf;
    LOOP
      ln_cnt := ln_cnt + 1;
	  ln_is_je_trx_code := 'FALSE';--Added for NAIT-138934 Wells Fargo Bank Transaction Code Change
       BEGIN
        FETCH lcu_gl_line_wf
        INTO  ln_cash_bank_account_id,
		     ln_master_bank_acct_id --added version#2.1
             ,ln_statement_number
             ,ld_statement_date
             ,ln_statement_line_number
             ,ln_statement_line_id
             ,ld_trx_date
             ,lc_trx_type
             ,ln_amount
             ,ln_header_id
             ,lc_invoice_text
             ,lc_trx_code
             ,lc_currency_code
             ,lc_segment1
             ,lc_segment2
             ,lc_segment3
             ,lc_segment4
             ,lc_segment5
             ,lc_segment6
             ,lc_segment7;
        EXIT WHEN lcu_gl_line_wf%NOTFOUND OR lcu_gl_line_wf%NOTFOUND IS NULL;
		
		--<Start> Added for NAIT-138934 Wells Fargo Bank Transaction Code Change
		BEGIN
		    SELECT 'TRUE'
		    INTO ln_is_je_trx_code
		    FROM xx_fin_translatedefinition XFTD,xx_fin_translatevalues XFTV
		    WHERE XFTD.translate_id = XFTV.translate_id
		    AND XFTD.translation_name = 'XX_CM_E1319_STORE_OS_CC'
		    AND XFTV.source_value1 = 'BSTMT_TRX_CODE'
		    AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
		    AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
		    AND XFTV.enabled_flag = 'Y'
		    AND XFTD.enabled_flag = 'Y'
		    AND target_value1 = lc_trx_code;
		EXCEPTION
		    WHEN NO_DATA_FOUND then
			ln_is_je_trx_code:= 'FALSE';
		END;
		--<END> Added for NAIT-138934					  
																				   
	    BEGIN
        ln_cnt1 := ln_cnt1 + 1;
         ---------------------------------------------------------------------------
         -- This statement will fetch the Asset Account for a given bank_account_id
         ---------------------------------------------------------------------------
		 
		IF (ln_is_je_trx_code = 'FALSE') THEN		--Added for NAIT-138934 Wells Fargo Bank Transaction Code Change
           SELECT ABA.bank_account_id
                 ,ABA.bank_account_num
                 ,ABA.currency_code
                 ,hou.set_of_books_id
		         ,cbau.org_id
                 ,GCC.segment1
                 ,GCC.segment2
                 ,GCC.segment3
                 ,GCC.segment4
                 ,GCC.segment5
                 ,GCC.segment6
                 ,GCC.segment7
           INTO   ln_asset_bank_account_id
                 ,lc_bank_acct_num
                 ,lc_currency_code
                 ,ln_sob_id
                 ,ln_org_id
                 ,lc_ba_segment1
                 ,lc_ba_segment2
                 ,lc_ba_segment3
                 ,lc_ba_segment4
                 ,lc_ba_segment5
                 ,lc_ba_segment6
                 ,lc_ba_segment7
           FROM   gl_code_combinations GCC
                 ,ce_bank_accounts     ABA
                 ,ce_bank_acct_uses    cbau
		         ,hr_operating_units   hou
           WHERE  ABA.asset_code_combination_id    = GCC.code_combination_id
          -- AND    ABA.bank_account_id              = ln_cash_bank_account_id
		  and aba.bank_Account_id = ln_master_bank_acct_id
           AND    NVL (ABA.end_date, SYSDATE + 1) > TRUNC (SYSDATE)
           AND aba.bank_account_id = cbau.bank_account_id
           AND hou.organization_id = cbau.org_id  ;
		   --<START> Added for NAIT-138934  Wells Fargo Bank Transaction Code Change
		ELSE 
		   SELECT ABA.bank_account_id
                 ,ABA.bank_account_num
                 ,ABA.currency_code
                 ,hou.set_of_books_id
		         ,cbau.org_id
                 ,GCC.segment1
                 ,GCC.segment2
                 ,GCC.segment3
                 ,GCC.segment4
                 ,GCC.segment5
                 ,GCC.segment6
                 ,GCC.segment7
           INTO   ln_asset_bank_account_id
                 ,lc_bank_acct_num
                 ,lc_currency_code
                 ,ln_sob_id
                 ,ln_org_id
                 ,lc_ba_segment1
                 ,lc_ba_segment2
                 ,lc_ba_segment3
                 ,lc_ba_segment4
                 ,lc_ba_segment5
                 ,lc_ba_segment6
                 ,lc_ba_segment7
           FROM   gl_code_combinations GCC
                 ,ce_bank_accounts     ABA
                 ,ce_bank_acct_uses    cbau
		         ,hr_operating_units   hou
           WHERE  ABA.cash_clearing_ccid    = GCC.code_combination_id
          -- AND    ABA.bank_account_id              = ln_cash_bank_account_id
		  and aba.bank_Account_id = ln_master_bank_acct_id
           AND    NVL (ABA.end_date, SYSDATE + 1) > TRUNC (SYSDATE)
           AND aba.bank_account_id = cbau.bank_account_id
           AND hou.organization_id = cbau.org_id  ;		   
		END IF;
		   --<END> Added for NAIT-138934 Wells Fargo Bank Transaction Code Change
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RAISE EX_ERROR_WF;
        WHEN OTHERS THEN
         RAISE EX_ERROR_WF;
        END;
        ld_gl_date := to_char(to_date(p_gl_date,'YYYY/MM/DD HH24:MI:SS'));
        lpv_description := lc_bank_acct_num||'-'||ln_statement_number||'-'||ln_statement_line_number||'-'||lc_trx_code||'-'||lc_invoice_text;

		 FND_FILE.PUT_LINE(FND_FILE.log, 'ln_asset_bank_account_id : ' || ln_asset_bank_account_id ||','||'lc_bank_acct_num : ' || lc_bank_acct_num
		 ||','||'ln_sob_id : ' || ln_sob_id ||','||'lc_currency_code : ' || lc_currency_code ||','||'ln_org_id : ' || ln_org_id
		 ||','|| 'lc_ba_segment1 : ' || lc_ba_segment1 ||','|| 'lc_ba_segment2 : ' || lc_ba_segment2
		 ||','|| 'lc_ba_segment3 : ' || lc_ba_segment3 ||','|| 'lc_ba_segment4 : ' || lc_ba_segment4
		 ||','|| 'lc_ba_segment5 : ' || lc_ba_segment5 ||','|| 'lc_ba_segment6 : ' || lc_ba_segment6
		 ||','|| 'lc_ba_segment7 : ' || lc_ba_segment7 ||','|| 'lpv_description : ' || lpv_description);


        IF UPPER(lc_trx_type) = 'CREDIT' OR UPPER(lc_trx_type) = 'MISC_CREDIT' THEN

          lc_cr_company       := lc_segment1;
          lc_cr_cost_center   := lc_segment2;
          lc_cr_account       := lc_segment3;
          lc_cr_location      := lc_segment4;
          lc_cr_intercompany  := lc_segment5;
          lc_cr_channel       := lc_segment6;
          lc_cr_future        := lc_segment7;
          lc_dr_company       := lc_ba_segment1;
          lc_dr_cost_center   := lc_ba_segment2;
          lc_dr_account       := lc_ba_segment3;
          lc_dr_location      := lc_ba_segment4;
          lc_dr_intercompany  := lc_ba_segment5;
          lc_dr_channel       := lc_ba_segment6;
          lc_dr_future        := lc_ba_segment7;
        ELSE

          lc_dr_company       := lc_segment1;
          lc_dr_cost_center   := lc_segment2;
          lc_dr_account       := lc_segment3;
          lc_dr_location      := lc_segment4;
          lc_dr_intercompany  := lc_segment5;
          lc_dr_channel       := lc_segment6;
          lc_dr_future        := lc_segment7;
          lc_cr_company       := lc_ba_segment1;
          lc_cr_cost_center   := lc_ba_segment2;
          lc_cr_account       := lc_ba_segment3;
          lc_cr_location      := lc_ba_segment4;
          lc_cr_intercompany  := lc_ba_segment5;
          lc_cr_channel       := lc_ba_segment6;
          lc_cr_future        := lc_ba_segment7;
        END IF;

        FND_FILE.PUT_LINE(FND_FILE.log, 'ln_user_id : ' || ln_user_id ||','||'ln_group_id : ' || ln_group_id  ||','||'ld_gl_date :' || ld_gl_date ||','||'ln_sob_id : ' || ln_sob_id ||','||'lc_currency_code : ' || lc_currency_code ||','||'ln_statement_number : ' || ln_statement_number ||','|| 'ln_statement_line_number : ' || ln_statement_line_number ||','|| 'ln_amount : ' || ln_amount);

        xx_gl_interface_pkg.create_stg_jrnl_line(
                                                 p_status => 'NEW'
                                               , p_date_created => SYSDATE
                                               , p_created_by => ln_user_id
                                               , p_actual_flag => 'A'
                                               , p_group_id => ln_group_id
                                               , p_batch_name => ld_trx_date
                                               , p_batch_desc => ' '
                                               , p_user_source_name => 'OD CM Other'
                                               , p_user_catgory_name => 'Other'
                                               , p_set_of_books_id => ln_sob_id
                                               , p_accounting_date => NVL(ld_gl_date,SYSDATE)
                                               , p_currency_code => lc_currency_code
                                               , p_company => lc_cr_company
                                               , p_cost_center => lc_cr_cost_center
                                               , p_account => lc_cr_account
                                               , p_location => lc_cr_location
                                               , p_intercompany => lc_cr_intercompany
                                               , p_channel => lc_cr_channel
                                               , p_future => lc_cr_future
                                               , p_entered_dr => 0
                                               , p_entered_cr => ln_amount
                                               , p_je_name => NULL
                                               , p_je_reference => ln_group_id
                                               , p_je_line_dsc => SUBSTR (lpv_description , 1 , 240 )
                                               , x_output_msg => lc_output_msg1
                                               );

        FND_FILE.PUT_LINE(FND_FILE.log, 'lc_Output_Message1 - Credit : ' || lc_output_msg1);
        FND_FILE.PUT_LINE(FND_FILE.Output,(RPAD(lc_bank_acct_num,25,' ')
                                          ||RPAD(ln_statement_number,21,' ')
                                          ||RPAD(lc_currency_code,12,' ')
                                          ||RPAD(ld_statement_date,18,' ')
                                          ||RPAD(ln_statement_line_number,18,' ')
                                          ||RPAD(lc_trx_code,11,' ')
                                          ||RPAD(lc_dr_company||'.'||lc_dr_cost_center||'.'||lc_dr_account||'.'||lc_dr_location||'.'||lc_dr_intercompany||'.'||lc_dr_channel||'.'||lc_dr_future,45,' ')
                                          ||LPAD(LTRIM(RTRIM(TO_CHAR(ln_amount,'$999,999,999,990.00'))),26,' ')
                                          ||LPAD('$0.00',26,' ')
                                          )
                         );

        xx_gl_interface_pkg.create_stg_jrnl_line(
                                                  p_status => 'NEW'
                                                , p_date_created => SYSDATE
                                                , p_created_by => ln_user_id
                                                , p_actual_flag => 'A'
                                                , p_group_id => ln_group_id
                                                , p_batch_name => ld_trx_date
                                                , p_batch_desc => ' '
                                                , p_user_source_name => 'OD CM Other'
                                                , p_user_catgory_name => 'Other'
                                                , p_set_of_books_id => ln_sob_id
                                                , p_accounting_date => NVL(ld_gl_date,SYSDATE)
                                                , p_currency_code => lc_currency_code
                                                , p_company => lc_dr_company
                                                , p_cost_center => lc_dr_cost_center
                                                , p_account => lc_dr_account
                                                , p_location => lc_dr_location
                                                , p_intercompany => lc_dr_intercompany
                                                , p_channel => lc_dr_channel
                                                , p_future => lc_dr_future
                                                , p_entered_dr => ln_amount
                                                , p_entered_cr => 0
                                                , p_je_name => NULL
                                                , p_je_reference => ln_group_id
                                                , p_je_line_dsc => SUBSTR (lpv_description , 1 , 240 )
                                                , x_output_msg => lc_output_msg
                                                );
        FND_FILE.PUT_LINE(FND_FILE.log, 'lc_Output_Message1 - Debit : ' || lc_output_msg);
        FND_FILE.PUT_LINE(FND_FILE.Output,(RPAD(lc_bank_acct_num,25,' ')
                                          ||RPAD(ln_statement_number,21,' ')
                                          ||RPAD(lc_currency_code,12,' ')
                                          ||RPAD(ld_statement_date,18,' ')
                                          ||RPAD(ln_statement_line_number,18,' ')
                                          ||RPAD(lc_trx_code,11,' ')
                                          ||RPAD(lc_cr_company||'.'||lc_cr_cost_center||'.'||lc_cr_account||'.'||lc_cr_location||'.'||lc_cr_intercompany||'.'||lc_cr_channel||'.'||lc_cr_future,45,' ')
                                          ||LPAD('$0.00',26,' ')
                                          ||LPAD(LTRIM(RTRIM(TO_CHAR(ln_amount,'$999,999,999,990.00'))),26,' ')
                                          )
                         );

        ------------------------------------------------------
         -- Update the processed record with the status as 'Y'
        -----------------------------------------------------
        
        UPDATE ce_statement_lines
        SET    attribute2          = 'PROC-E2027-YES'	
        WHERE  statement_line_id   = ln_statement_line_id
        AND    statement_header_id = ln_header_id;
		COMMIT;
		
		--<START> Added for NAIT-138934 Wells Fargo Bank Transaction Code Change
		--update_ce_stm_line_external(ln_is_je_trx_code,ln_statement_line_id,ln_header_id);
		IF (ln_is_je_trx_code = 'TRUE') THEN
		    BEGIN  
		        UPDATE ce_statement_lines
		        SET    status = 'EXTERNAL'	
		        WHERE  statement_line_id   = ln_statement_line_id
		        AND    statement_header_id = ln_header_id;
			    COMMIT;
		    EXCEPTION
		    WHEN OTHERS THEN
			FND_FILE.PUT_LINE(FND_FILE.LOG,'Error updating ce_statement_lines with status as External'|| SQLERRM);
		    END;
		END IF;
		--<END> Added for NAIT-138934 Wells Fargo Bank Transaction Code Change
        ln_cnt2 := ln_cnt2 + 1;
      EXCEPTION
        WHEN EX_ERROR_WF THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in child procedure:'|| SQLERRM);
      END;
      IF ln_cnt >= 2000 THEN
        COMMIT;
        ln_cnt :=0;
      END IF;
    END LOOP;
	END;
    FND_FILE.PUT_LINE(FND_FILE.Output,'                                                                                                                                       ');
    FND_FILE.PUT_LINE(FND_FILE.Output,'                                                                                                                                       ');
    FND_FILE.PUT_LINE(FND_FILE.Output,'                                ***************** End of Wells fargo Store Accounts Report *******************                                                    ');
    FND_FILE.PUT_LINE(FND_FILE.log,'Total No. Of Wells Fargo Statement Lines fetched : '||ln_cnt1);
    FND_FILE.PUT_LINE(FND_FILE.log,'Total No. Of Wells Fargo Statements Lines inserted in GL Tables : '||ln_cnt2);
    COMMIT;

END CREATE_GL_INTRF_WF_LINE;


-- +===================================================================+
-- | Name  : CREATE_GL_INTRF_STG_LINE_MAIN                             |
-- | Description      : This Procedure can be used to insert GL Journal|
-- |                    entry line into the XX_GL_INTERFACE_NA_STG     |
-- |                    table.                                         |
-- |                                                                   |
-- | Parameters :p_bank_branch_id                                      |
-- |             p_bank_account_id                                     |
-- |             p_statement_number_from                               |
-- |             p_statement_number_to                                 |
-- |             p_statement_date_from                                 |
-- |             p_statement_date_to                                   |
-- |             p_gl_date                                             |
-- |                                                                   |
-- +===================================================================+
PROCEDURE CREATE_GL_INTRF_STG_LINE_MAIN (
           x_errbuf                OUT NOCOPY  VARCHAR2
          ,x_retcode               OUT NOCOPY  NUMBER
          ,p_bank_branch_id        IN NUMBER
          ,p_bank_account_id       IN NUMBER
          ,p_statement_number_from IN VARCHAR2
          ,p_statement_number_to   IN VARCHAR2
          ,p_statement_date_from   IN VARCHAR2
          ,p_statement_date_to     IN VARCHAR2
          ,p_gl_date               IN VARCHAR2
          )
IS
  ------------------------------------------------------------------
  -- Cursor to get all the statement lines based on the parameters
  -- which has a cash account value in the Attribute10 field of the
  -- CE_STATEMENT_LINES table and which is not yet processed
  ------------------------------------------------------------------

	CURSOR lcu_gl_line
	IS
	  SELECT 
	  --Hint added(NAIT-140412)
	  /*+ leading(csh) ordered use_nl(csh,csl,ctc) index(csl,CE_STATEMENT_LINES_N1) use_merge(ctc) full(ctc)*/
	  CSH.bank_account_id ,
		CSH.statement_number ,
		CSH.statement_date ,
		CSL.line_number ,
		CSL.statement_line_id ,
		CSL.trx_date ,
		CSL.trx_type ,
		CSL.amount ,
		CSL.statement_header_id ,
		CSL.invoice_text ,
		CTC.trx_code ,
		ABA.currency_code ,
		GCC.segment1 ,
		GCC.segment2 ,
		GCC.segment3 ,
		GCC.segment4 ,
		GCC.segment5 ,
		GCC.segment6 ,
		GCC.segment7
	  FROM ce_statement_headers CSH ,
		ce_statement_lines CSL ,
		ce_transaction_codes CTC ,
		gl_code_combinations GCC
		--,ap_bank_accounts       ABA   -- Commented for the R12 Retrofit
		,
		ce_bank_accounts ABA -- Added as part of R12 Retrofit
	  WHERE CSH.statement_header_id = CSL.statement_header_id
	  AND CSH.bank_account_id       = CTC.bank_account_id
	  AND CTC.bank_account_id       = ABA.bank_account_id
	  AND NVL(CSL.attribute2,'N')  <> 'PROC-E2027-YES'
	  AND CSL.status               <> 'RECONCILED' -- Added this condition so that Reconciled  lines  doesnt get picked by E2027 process - QC Defect # 20234
	  AND CSH.bank_account_id       = NVL(p_bank_account_id,CSH.bank_account_id)
	  AND ABA.bank_branch_id        = NVL(p_bank_branch_id,ABA.bank_branch_id)
	  AND CSH.statement_number BETWEEN NVL(p_statement_number_from,CSH.statement_number) AND NVL(p_statement_number_to,CSH.statement_number)
	  AND fnd_date.canonical_to_date(CSH.statement_date) BETWEEN NVL(fnd_date.canonical_to_date(p_statement_date_from),fnd_date.canonical_to_date(CSH.statement_date)) AND NVL(fnd_date.canonical_to_date(p_statement_date_to),fnd_date.canonical_to_date(CSH.statement_date))
	  AND CSL.trx_code               = CTC.trx_code -- modified for Retrofit to R12
	  AND GCC.code_combination_id    = CTC.attribute10
	  AND CTC.attribute10           IS NOT NULL
	  /*Ver 2.0 Starts here*/
	  AND csl.statement_line_id NOT IN
		(SELECT
		  --Removed the hint from here and used in the parent select clause (NAIT-140412)
		  CSL.statement_line_id
		FROM ce_statement_headers csh ,
		  ce_statement_lines csl ,
		  ce_transaction_codes ctc ,
		  ce_bank_accounts cba ,
		  gl_code_combinations gcc ,
		  Hz_parties hp
		WHERE csl.attribute15      IS NULL
		AND csl.statement_header_id = csh.statement_header_id
		AND csh.bank_account_id     = NVL(p_bank_account_id,CSH.bank_account_id)
		AND CSH.statement_number BETWEEN NVL(p_statement_number_from,CSH.statement_number) AND NVL(p_statement_number_to,CSH.statement_number)
		AND fnd_date.canonical_to_date(CSH.statement_date) BETWEEN NVL(fnd_date.canonical_to_date(p_statement_date_from),fnd_date.canonical_to_date(CSH.statement_date)) AND NVL(fnd_date.canonical_to_date(p_statement_date_to),fnd_date.canonical_to_date(CSH.statement_date))
		AND lpad(SUBSTR (cba.agency_location_code, 3), 9,'0')          = SUBSTR (csl.CUSTOMER_TEXT,3)
		AND NVL(CSL.attribute2,'N')                                   <> 'PROC-E2027-YES'
		AND csl.status!                                                ='RECONCILED'
		AND SUBSTR (csl.CUSTOMER_TEXT,3)                               =lpad(gcc.segment4, 9,'0')
		AND gcc.code_combination_id                                    = CTC.attribute10
		AND NVL (cba.end_date, SYSDATE + 1)                            > TRUNC (SYSDATE)
		AND csl.trx_code                                               = ctc.trx_code
		AND ctc.bank_Account_id                                        =cba.bank_Account_id
		AND CTC.attribute10                                           IS NOT NULL
		AND hp.party_id                                                = cba.bank_id 
		--AND hp.party_name                                              ='WELLS FARGO BANK' --Commented for NAIT-140412
		--<START> Added for NAIT-140412	
		AND hp.party_name IN
					(SELECT upper(XFTV.source_value2)
					 FROM xx_fin_translatedefinition XFTD,xx_fin_translatevalues XFTV
					 WHERE XFTD.translate_id = XFTV.translate_id
					 AND XFTD.translation_name = 'XX_CM_E1319_STORE_OS_CC'
					 AND XFTV.source_value1 = 'BANK'
					 AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
					 AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
					 AND XFTV.enabled_flag = 'Y'
					 AND XFTD.enabled_flag = 'Y')
		--<END> Added for NAIT-140412	
		AND hp.party_type                                              ='ORGANIZATION'
		AND regexp_replace(cba.bank_account_name, '[^[:digit:]]', '') IS NOT NULL
		AND gcc.segment4                                               = SUBSTR (cba.agency_location_code, 3)
		);

 /*	Ver 2.0

  ln_cash_bank_account_id    ce_statement_headers.bank_account_id%TYPE;  --Commented ce_statement_headers_all as part of R12 Retrofit
  ln_statement_number        ce_statement_headers.statement_number%TYPE; --Commented ce_statement_headers_all as part of R12 Retrofit
  ln_header_id               ce_statement_lines.statement_header_id%TYPE;
  ld_statement_date          ce_statement_headers.statement_date%TYPE;   --Commented ce_statement_headers_all as part of R12 Retrofit
  ln_statement_line_number   ce_statement_lines.line_number%TYPE;
  ln_statement_line_id       ce_statement_lines.statement_line_id%TYPE;
  ld_trx_date                ce_statement_lines.trx_date%TYPE;
  lc_trx_type                ce_statement_lines.trx_type%TYPE;
  ln_amount                  ce_statement_lines.amount%TYPE;
  lc_invoice_text            ce_statement_lines.invoice_text%TYPE;
  lc_trx_code                ce_transaction_codes.trx_code%TYPE;
  ln_user_id                 NUMBER := fnd_global.user_id;
  ln_group_id                NUMBER;
  ld_gl_date                 VARCHAR2(20);

  /* Defect #37859 - Removed ap_bank references
  ln_asset_bank_account_id   ap_bank_accounts_all.bank_account_id%TYPE;
  lc_bank_acct_num           ap_bank_accounts_all.bank_account_num%TYPE;
  lc_bank_account            ap_bank_accounts_all.bank_account_num%TYPE;
  lc_currency_code           ap_bank_accounts_all.currency_code%TYPE;
  ln_sob_id                  ap_bank_accounts_all.set_of_books_id%TYPE;
  ln_org_id                  ap_bank_accounts_all.org_id%TYPE;
  lc_bank_name               ap_bank_branches.bank_name%TYPE;*/

 /*Ver 2.0
  ln_asset_bank_account_id   ce_bank_accounts.bank_account_id%TYPE;
  lc_bank_acct_num           ce_bank_accounts.bank_account_num%TYPE;
  lc_bank_account            ce_bank_accounts.bank_account_num%TYPE;
  lc_currency_code           ce_bank_accounts.currency_code%TYPE;
  ln_sob_id                  hr_operating_units.set_of_books_id%TYPE;
  ln_org_id                  ce_bank_acct_uses.org_id%TYPE;
  lc_bank_name               hz_organization_profiles.organization_name%TYPE;
  lpv_description            VARCHAR2(240);
  lc_output_msg              VARCHAR2(240);
  lc_output_msg1             VARCHAR2(240);
  --lc_bank_branch           ap_bank_branches.bank_branch_name%TYPE; --commented defect#37859
  lc_bank_branch	     hz_parties.party_name%TYPE; --Added for defect#37859
  lc_ba_segment1             gl_code_combinations.segment1%TYPE;
  lc_ba_segment2             gl_code_combinations.segment2%TYPE;
  lc_ba_segment3             gl_code_combinations.segment3%TYPE;
  lc_ba_segment4             gl_code_combinations.segment4%TYPE;
  lc_ba_segment5             gl_code_combinations.segment5%TYPE;
  lc_ba_segment6             gl_code_combinations.segment6%TYPE;
  lc_ba_segment7             gl_code_combinations.segment7%TYPE;
  lc_segment1                gl_code_combinations.segment1%TYPE;
  lc_segment2                gl_code_combinations.segment2%TYPE;
  lc_segment3                gl_code_combinations.segment3%TYPE;
  lc_segment4                gl_code_combinations.segment4%TYPE;
  lc_segment5                gl_code_combinations.segment5%TYPE;
  lc_segment6                gl_code_combinations.segment6%TYPE;
  lc_segment7                gl_code_combinations.segment7%TYPE;
--  lc_cr_ccid                 VARCHAR2(25);
--  lc_dr_ccid                 VARCHAR2(25);
  lc_cr_company              gl_code_combinations.segment1%TYPE;
  lc_cr_cost_center          gl_code_combinations.segment2%TYPE;
  lc_cr_account              gl_code_combinations.segment3%TYPE;
  lc_cr_location             gl_code_combinations.segment4%TYPE;
  lc_cr_intercompany         gl_code_combinations.segment5%TYPE;
  lc_cr_channel              gl_code_combinations.segment6%TYPE;
  lc_cr_future               gl_code_combinations.segment7%TYPE;
  lc_dr_company              gl_code_combinations.segment1%TYPE;
  lc_dr_cost_center          gl_code_combinations.segment2%TYPE;
  lc_dr_account              gl_code_combinations.segment3%TYPE;
  lc_dr_location             gl_code_combinations.segment4%TYPE;
  lc_dr_intercompany         gl_code_combinations.segment5%TYPE;
  lc_dr_channel              gl_code_combinations.segment6%TYPE;
  lc_dr_future               gl_code_combinations.segment7%TYPE;
  ln_cnt                     NUMBER := 0;
  ln_cnt1                    NUMBER := 0;
  ln_cnt2                    NUMBER := 0;
  EX_ERROR                   EXCEPTION;
  EX_ERROR_WF                EXCEPTION;
 --Commenting all variables here.
 /*Ver 2.0 End here*/

  BEGIN
  --V2.0-start
	ln_cnt    := 0;
	ln_cnt1   := 0;
	ln_cnt2   := 0;
	--v2.0 end--
    
    IF p_bank_branch_id IS NOT NULL THEN
    BEGIN
        SELECT bank_branch_name, bank_name
          INTO lc_bank_branch, lc_bank_name
          FROM ce_bank_branches_v--ap_bank_branches Commented and added as part of R12 retrofit
         WHERE branch_party_id = p_bank_branch_id;--bank_branch_id = p_bank_branch_id;Commented and added as part of R12 retrofit
    Exception
         When Others Then
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in fetching the bank branch name.');
    END;
    END IF;

    IF p_bank_account_id IS NOT NULL
    THEN
    BEGIN
        SELECT bank_account_num
          INTO lc_bank_account
          FROM ce_bank_accounts--ap_bank_accounts Commented and added as part of R12 retrofit
         WHERE bank_account_id = p_bank_account_id;
    Exception
         When Others Then
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in fetching the bank account number.');
    END;
    END IF;
    FND_FILE.PUT_LINE(FND_FILE.Output,'                                             Custom Journal Entry Creation Execution Report                                                     Report Date :  ' ||to_char(sysdate,'DD-MON-YY HH:MM'));
    FND_FILE.PUT_LINE(FND_FILE.Output,'                                                                                                                                                                  ');
    FND_FILE.PUT_LINE(FND_FILE.Output,'                                                                                                                                                                  ');
    FND_FILE.PUT_LINE(FND_FILE.Output,'                                                                                                                                                                  ');
    FND_FILE.PUT_LINE(FND_FILE.Output,' Bank Name             :' || lc_bank_name);
    FND_FILE.PUT_LINE(FND_FILE.Output,' Bank Branch Name      :' || lc_bank_branch);
    FND_FILE.PUT_LINE(FND_FILE.Output,' Bank Account Number   :' || lc_bank_account);
    FND_FILE.PUT_LINE(FND_FILE.Output,' Statement Number From :' || p_statement_number_from);
    FND_FILE.PUT_LINE(FND_FILE.Output,' Statement Number to   :' || p_statement_number_to);
    FND_FILE.PUT_LINE(FND_FILE.Output,' Statement Date From   :' || p_statement_date_from);
    FND_FILE.PUT_LINE(FND_FILE.Output,' Statement Date To     :' || p_statement_date_to);
    FND_FILE.PUT_LINE(FND_FILE.Output,' GL Date               :' || p_gl_date);
    FND_FILE.PUT_LINE(FND_FILE.Output,'                                                                                                                                                                  ');
    FND_FILE.PUT_LINE(FND_FILE.Output,'                                                                                                                                                                  ');
    FND_FILE.PUT_LINE(FND_FILE.Output,'Bank Acc #               Statement #          Currency    Statement Date    Statement Line    TRX Code   GL Acct String                                             DR $ Amount                CR $ Amount');
    FND_FILE.PUT_LINE(FND_FILE.Output,'----------               -----------          --------    --------------    --------------    --------   --------------                                             ------------               -----------');

    BEGIN
         SELECT gl_interface_control_s.NEXTVAL
         INTO   ln_group_id
         FROM   SYS.DUAL;
    EXCEPTION
      WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in GL Interface sequence.');
    END;

    OPEN lcu_gl_line;
    LOOP
      ln_cnt := ln_cnt + 1;
       BEGIN
        FETCH lcu_gl_line
        INTO  ln_cash_bank_account_id
             ,ln_statement_number
             ,ld_statement_date
             ,ln_statement_line_number
             ,ln_statement_line_id
             ,ld_trx_date
             ,lc_trx_type
             ,ln_amount
             ,ln_header_id
             ,lc_invoice_text
             ,lc_trx_code
             ,lc_currency_code
             ,lc_segment1
             ,lc_segment2
             ,lc_segment3
             ,lc_segment4
             ,lc_segment5
             ,lc_segment6
             ,lc_segment7;
        EXIT WHEN lcu_gl_line%NOTFOUND OR lcu_gl_line%NOTFOUND IS NULL;

        BEGIN
        ln_cnt1 := ln_cnt1 + 1;
         ---------------------------------------------------------------------------
         -- This statement will fetch the Asset Account for a given bank_account_id
         ---------------------------------------------------------------------------
           SELECT ABA.bank_account_id
                 ,ABA.bank_account_num
                 ,ABA.currency_code
                 ,hou.set_of_books_id      --   aba.set_of_books_id   ----Changed for R12 retrofit
		 ,cbau.org_id              -- Added as part of R12 Retrofit
                 --,ABA.set_of_books_id    -- Commented as part of R12 Retrofit
                 --,ABA.org_id             -- Commented as part of R12 Retrofit
                 ,GCC.segment1
                 ,GCC.segment2
                 ,GCC.segment3
                 ,GCC.segment4
                 ,GCC.segment5
                 ,GCC.segment6
                 ,GCC.segment7
           INTO   ln_asset_bank_account_id
                 ,lc_bank_acct_num
                 ,lc_currency_code
                 ,ln_sob_id
                 ,ln_org_id
                 ,lc_ba_segment1
                 ,lc_ba_segment2
                 ,lc_ba_segment3
                 ,lc_ba_segment4
                 ,lc_ba_segment5
                 ,lc_ba_segment6
                 ,lc_ba_segment7
           FROM   gl_code_combinations GCC
                 --,ap_bank_accounts     ABA --Commented as part of R12 Retrofit
                 ,ce_bank_accounts     ABA   --Added as part of R12 Retrofit
                 ,ce_bank_acct_uses    cbau  --Added as part of R12 retrofit
		 ,hr_operating_units   hou   --Added as part of R12 Retrofit
           WHERE  ABA.asset_code_combination_id    = GCC.code_combination_id
           AND    ABA.bank_account_id              = NVL(p_bank_account_id,ln_cash_bank_account_id)
           AND    NVL (ABA.end_date, SYSDATE + 1) > TRUNC (SYSDATE) --Changed Inactive_date to end_date as part of R12 retrofit
           AND aba.bank_account_id = cbau.bank_account_id             ----Added for R12 retrofit
           AND hou.organization_id = cbau.org_id  ;                  ----Added for R12 retrofit
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RAISE EX_ERROR;
        WHEN OTHERS THEN
         RAISE EX_ERROR;
        END;
        ld_gl_date := to_char(to_date(p_gl_date,'YYYY/MM/DD HH24:MI:SS'));
        lpv_description := lc_bank_acct_num||'-'||ln_statement_number||'-'||ln_statement_line_number||'-'||lc_trx_code||'-'||lc_invoice_text;

        IF UPPER(lc_trx_type) = 'CREDIT' OR UPPER(lc_trx_type) = 'MISC_CREDIT' THEN
          --ln_amount := get it from cursor
          -- lc_cr_ccid := trx code setup;
          -- lc_dr_ccid := bank acct setup;
          lc_cr_company       := lc_segment1;
          lc_cr_cost_center   := lc_segment2;
          lc_cr_account       := lc_segment3;
          lc_cr_location      := lc_segment4;
          lc_cr_intercompany  := lc_segment5;
          lc_cr_channel       := lc_segment6;
          lc_cr_future        := lc_segment7;
          lc_dr_company       := lc_ba_segment1;
          lc_dr_cost_center   := lc_ba_segment2;
          lc_dr_account       := lc_ba_segment3;
          lc_dr_location      := lc_ba_segment4;
          lc_dr_intercompany  := lc_ba_segment5;
          lc_dr_channel       := lc_ba_segment6;
          lc_dr_future        := lc_ba_segment7;
        ELSE
          -- lc_dr_ccid := trx code setup;
          -- lc_cr_ccid := bank acct setup;
          lc_dr_company       := lc_segment1;
          lc_dr_cost_center   := lc_segment2;
          lc_dr_account       := lc_segment3;
          lc_dr_location      := lc_segment4;
          lc_dr_intercompany  := lc_segment5;
          lc_dr_channel       := lc_segment6;
          lc_dr_future        := lc_segment7;
          lc_cr_company       := lc_ba_segment1;
          lc_cr_cost_center   := lc_ba_segment2;
          lc_cr_account       := lc_ba_segment3;
          lc_cr_location      := lc_ba_segment4;
          lc_cr_intercompany  := lc_ba_segment5;
          lc_cr_channel       := lc_ba_segment6;
          lc_cr_future        := lc_ba_segment7;
        END IF;

        FND_FILE.PUT_LINE(FND_FILE.log, 'ln_user_id : ' || ln_user_id ||','||'ln_group_id : ' || ln_group_id  ||','||'ld_gl_date :' || ld_gl_date ||','||'ln_sob_id : ' || ln_sob_id ||','||'lc_currency_code : ' || lc_currency_code ||','||'ln_statement_number : ' || ln_statement_number ||','|| 'ln_statement_line_number : ' || ln_statement_line_number ||','|| 'ln_amount : ' || ln_amount);

        xx_gl_interface_pkg.create_stg_jrnl_line(
                                                 p_status => 'NEW'
                                               , p_date_created => SYSDATE
                                               , p_created_by => ln_user_id
                                               , p_actual_flag => 'A'
                                               , p_group_id => ln_group_id
                                               , p_batch_name => ld_trx_date
                                               , p_batch_desc => ' '
                                               , p_user_source_name => 'OD CM Other'
                                               , p_user_catgory_name => 'Other'
                                               , p_set_of_books_id => ln_sob_id
                                               , p_accounting_date => NVL(ld_gl_date,SYSDATE)
                                               , p_currency_code => lc_currency_code
                                               , p_company => lc_cr_company
                                               , p_cost_center => lc_cr_cost_center
                                               , p_account => lc_cr_account
                                               , p_location => lc_cr_location
                                               , p_intercompany => lc_cr_intercompany
                                               , p_channel => lc_cr_channel
                                               , p_future => lc_cr_future
                                               , p_entered_dr => 0
                                               , p_entered_cr => ln_amount
                                               , p_je_name => NULL
                                               , p_je_reference => ln_group_id
                                               , p_je_line_dsc => SUBSTR (lpv_description , 1 , 240 )
                                               , x_output_msg => lc_output_msg1
                                               );

        FND_FILE.PUT_LINE(FND_FILE.log, 'lc_Output_Message1 - Credit : ' || lc_output_msg1);
        FND_FILE.PUT_LINE(FND_FILE.Output,(RPAD(lc_bank_acct_num,25,' ')
                                          ||RPAD(ln_statement_number,21,' ')
                                          ||RPAD(lc_currency_code,12,' ')
                                          ||RPAD(ld_statement_date,18,' ')
                                          ||RPAD(ln_statement_line_number,18,' ')
                                          ||RPAD(lc_trx_code,11,' ')
                                          ||RPAD(lc_dr_company||'.'||lc_dr_cost_center||'.'||lc_dr_account||'.'||lc_dr_location||'.'||lc_dr_intercompany||'.'||lc_dr_channel||'.'||lc_dr_future,45,' ')
                                          ||LPAD(LTRIM(RTRIM(TO_CHAR(ln_amount,'$999,999,999,990.00'))),26,' ')
                                          ||LPAD('$0.00',26,' ')
                                          )
                         );

        xx_gl_interface_pkg.create_stg_jrnl_line(
                                                  p_status => 'NEW'
                                                , p_date_created => SYSDATE
                                                , p_created_by => ln_user_id
                                                , p_actual_flag => 'A'
                                                , p_group_id => ln_group_id
                                                , p_batch_name => ld_trx_date
                                                , p_batch_desc => ' '
                                                , p_user_source_name => 'OD CM Other'
                                                , p_user_catgory_name => 'Other'
                                                , p_set_of_books_id => ln_sob_id
                                                , p_accounting_date => NVL(ld_gl_date,SYSDATE)
                                                , p_currency_code => lc_currency_code
                                                , p_company => lc_dr_company
                                                , p_cost_center => lc_dr_cost_center
                                                , p_account => lc_dr_account
                                                , p_location => lc_dr_location
                                                , p_intercompany => lc_dr_intercompany
                                                , p_channel => lc_dr_channel
                                                , p_future => lc_dr_future
                                                , p_entered_dr => ln_amount
                                                , p_entered_cr => 0
                                                , p_je_name => NULL
                                                , p_je_reference => ln_group_id
                                                , p_je_line_dsc => SUBSTR (lpv_description , 1 , 240 )
                                                , x_output_msg => lc_output_msg
                                                );
        FND_FILE.PUT_LINE(FND_FILE.log, 'lc_Output_Message1 - Debit : ' || lc_output_msg);
        FND_FILE.PUT_LINE(FND_FILE.Output,(RPAD(lc_bank_acct_num,25,' ')
                                          ||RPAD(ln_statement_number,21,' ')
                                          ||RPAD(lc_currency_code,12,' ')
                                          ||RPAD(ld_statement_date,18,' ')
                                          ||RPAD(ln_statement_line_number,18,' ')
                                          ||RPAD(lc_trx_code,11,' ')
                                          ||RPAD(lc_cr_company||'.'||lc_cr_cost_center||'.'||lc_cr_account||'.'||lc_cr_location||'.'||lc_cr_intercompany||'.'||lc_cr_channel||'.'||lc_cr_future,45,' ')
                                          ||LPAD('$0.00',26,' ')
                                          ||LPAD(LTRIM(RTRIM(TO_CHAR(ln_amount,'$999,999,999,990.00'))),26,' ')
                                          )
                         );

        ------------------------------------------------------
         -- Update the processed record with the status as 'Y'
        -----------------------------------------------------

        UPDATE ce_statement_lines
        SET    attribute2          = 'PROC-E2027-YES'
        WHERE  statement_line_id   = ln_statement_line_id
        AND    statement_header_id = ln_header_id;
        ln_cnt2 := ln_cnt2 + 1;
      EXCEPTION
        WHEN EX_ERROR THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in main procedure calling lcu_gl_line:'|| SQLERRM);
      END;
      IF ln_cnt >= 2000 THEN
        COMMIT;
        ln_cnt :=0;
      END IF;
    END LOOP;
    FND_FILE.PUT_LINE(FND_FILE.Output,'                                                                                                                                       ');
    FND_FILE.PUT_LINE(FND_FILE.Output,'                                                                                                                                       ');
    FND_FILE.PUT_LINE(FND_FILE.Output,'                                ***************** End of Report *******************                                                    ');
    FND_FILE.PUT_LINE(FND_FILE.log,'Total No. Of records fetched : '||ln_cnt1);
    FND_FILE.PUT_LINE(FND_FILE.log,'Total No. Of inserted in GL Tables : '||ln_cnt2);
    COMMIT;

   --Version 2.0 starts
    --END;
	BEGIN
	--<START> Added for NAIT-175362 	
	SELECT 1 INTO ln_WF
	FROM xx_fin_translatedefinition XFTD, xx_fin_translatevalues XFTV
	WHERE XFTD.translate_id = XFTV.translate_id
	AND XFTD.translation_name = 'XX_CM_E1319_STORE_OS_CC'
	AND XFTV.source_value1 = 'BANK'
	AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
	AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
	AND XFTV.enabled_flag = 'Y'
	AND XFTD.enabled_flag = 'Y'
	AND UPPER(XFTV.SOURCE_VALUE2) = UPPER(lc_bank_name)
    AND UPPER(XFTV.TARGET_VALUE1) = UPPER(lc_bank_branch);	
	
	IF ln_WF = 1
	THEN
	--<END> Added for NAIT-175362 
	
	  CREATE_GL_INTRF_WF_LINE(
			   p_bank_branch_id
			  ,p_bank_account_id
			  ,p_statement_number_from
			  ,p_statement_number_to
			  ,p_statement_date_from
			  ,p_statement_date_to
			  ,p_gl_date
			  );
			  
	 END IF; --NAIT-175362
    EXCEPTION
	    --<START> Added for NAIT-175362
	    WHEN NO_DATA_FOUND THEN
		   NULL;
		--<END> Added for NAIT-175362
		   
        WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in calling procedure CREATE_GL_INTRF_WF_LINE:'|| SQLERRM);
		  x_errbuf := 'ERROR with  PROC CREATE_GL_INTRF_WF_LINE :'||SQLERRM;
          x_retcode :=1;
	END;

EXCEPTION
WHEN OTHERS
THEN
           x_errbuf := 'ERROR with main PROC. :'||SQLERRM;
           x_retcode :=2;

END CREATE_GL_INTRF_STG_LINE_MAIN;
END XX_CE_CUST_JE_LINES_CREATE_PKG;
--Version 2.0 ends
/
show error;