create or replace PACKAGE BODY xx_gl_legacy_extract_pkg
AS
  -- +=================================================================================+
  -- |                       Office Depot - Project Simplify                           |
  -- +=================================================================================+
  -- | Name       : xx_gl_legacy_extract_pkg.pks                                      |
  -- | Description: Extension I2131_Oracle_GL_Feed_to_FCC for                          |
  -- |              OD: GL Monthly YTD Balance Extract Program                         |
  -- |                                                                                 |
  -- |Change Record                                                                    |
  -- |==============                                                                   |
  -- |Version   Date         Authors            Remarks                                |
  -- |========  ===========  ===============    ============================           |
  -- |1.0      29-JAN-2019   Priyam P        Creation                                  |
  -- |1.1      13-MAR-2019   Priyam P        Removed FTP program and zip to .dat common|
  -- |                                        file copy                                |
  -- |1.2      27-APR-2020  Vivek Kumar      Added For Added for NAIT-127524,Replace   |
  -- |                                       1000E to 1100E File                       |
  -- |2.0	   22-Oct-2021	Amit Kumar		NAIT-199392 -Split Changes
  ---+=================================================================================+
  -- +=================================================================================+
  -- |                                                                                 |
  -- |PROCEDURE                                                                        |
  -- |  gl_ytd_bal_monthly_extract                                                     |
  -- |                                                                                 |
  -- |DESCRIPTION                                                                      |
  -- | Main procedure to get GL Monthly YTD balance extract                            |
  -- |                                                                                 |
  -- |HISTORY                                                                          |
  -- | 1.0          Creation                                                           |
  -- |                                                                                 |
  -- |PARAMETERS                                                                       |
  -- |==========                                                                       |
  -- |NAME                    TYPE    DESCRIPTION                                      |
  -- |----------------------- ------- ----------------------------------------         |
  -- |x_errbuf                 OUT     Error message.                                  |
  -- |x_retcode                OUT     Error code.                                     |
  -- |p_sob_name               IN      Set of Books Name                               |
  -- |p_company                IN      Company Name                                    |
  -- |p_year                   IN      Year                                            |
  -- |p_period_name            IN      Period Name                                     |
  -- |p_acc_rolup_grp          IN      Account Rollup Group Name                       |
  -- |p_cc_rolup_grp           IN      Cost Center Rollup Group Name                   |
  -- |                                                                                 |
  -- |                                                                                 |
  -- |PREREQUISITES                                                                    |
  -- |  None.                                                                          |
  -- |                                                                                 |
  -- |CALLED BY                                                                        |
  -- |  None.                                                                          |
  -- +=================================================================================+

--v2.0/NAIT-199392 start
FUNCTION is_file_exist(
    p_directory IN VARCHAR2,
    p_filename  IN VARCHAR2)
  RETURN BOOLEAN
AS
  n_length     NUMBER;
  n_block_size NUMBER;
  b_exist      BOOLEAN := FALSE;
BEGIN
  UTL_FILE.fgetattr (p_directory, p_filename, b_exist, n_length, n_block_size);
  RETURN b_exist;
END is_file_exist; 

--v2.0/NAIT-199392  end

PROCEDURE gl_ytd_bal_monthly_extract(
    x_err_buff OUT NOCOPY VARCHAR2,
    x_ret_code OUT NOCOPY NUMBER,
    p_sob_name    IN VARCHAR2,
    p_company     IN VARCHAR2,
    p_year        IN VARCHAR2,
    p_period_name IN VARCHAR2)
  --- p_acc_rolup_grp IN VARCHAR2
  ---  p_cc_rolup_grp  IN VARCHAR2 )
AS
  lc_period_num        VARCHAR2 (2);
  lc_file_name         VARCHAR2 (100);
  ln_old_trans         NUMBER := 0;
  ln_trans_balances    NUMBER := 0;
  ln_cc_value_set_id   NUMBER;
  ln_acct_value_set_id NUMBER;
  lb_req_status1       BOOLEAN;
  lb_req_status2       BOOLEAN;
  lc_file_path         VARCHAR2 (500) := 'XXFIN_OUTBOUND_GLEXTRACT';
  lc_file_flag         VARCHAR2 (3)   := 'N';
  lc_source_file_path  VARCHAR2 (500);
  lc_dest_file_path    VARCHAR2 (500) := '$XXFIN_DATA/ftp/out/hyperion';
  lc_archive_file_path VARCHAR2 (500) := '$XXFIN_ARCHIVE/outbound';
  ---lc_archive_file_path VARCHAR2 (500) := '$XXFIN_DATA/ftp/out/hyperion';
  lc_source_file_name VARCHAR2 (1000);
  lc_dest_file_name   VARCHAR2 (1000);
  lc_dest_file_rename VARCHAR2 (1000);
  lc_phase            VARCHAR2 (50);
  lc_status           VARCHAR2 (50);
  lc_devphase         VARCHAR2 (50);
  lc_devstatus        VARCHAR2 (50);
  lc_message          VARCHAR2 (50);
  lc_error_msg        VARCHAR2 (4000);
  ln_req_id1          NUMBER (10);
  ln_req_id2          NUMBER (10);
  ln_msg_cnt          NUMBER := 0;
  ln_buffer BINARY_INTEGER   := 32767;
  ln_appl_id fnd_application.application_id%TYPE;
  ln_com_count NUMBER                                    := 0;
  lc_previous_company gl_code_combinations.segment1%type := NULL;
  /*ln_acc_rollup_grp   NUMBER;
  ln_cc_rollup_grp    NUMBER;
  lc_parent_acc       CONSTANT fnd_flex_value_norm_hierarchy.parent_flex_value%TYPE := 'P8000000';
  */
  ln_error_flag       NUMBER := 0;
  lc_period_status    VARCHAR2 (1);
  lc_period_name      VARCHAR2 (30);
  ln_tot_revenue      NUMBER := 0;
  ln_tot_expenses     NUMBER := 0;
  ln_net_income       NUMBER := 0;
  ln_tot_assets       NUMBER := 0;
  ln_tot_liability    NUMBER := 0;
  ln_tot_owner_equity NUMBER := 0;
  ln_tot_liab_equity  NUMBER := 0;
  ln_gl_appl_id       NUMBER := 200;
  --
  lc_version     VARCHAR2 (10);
  lc_scenario    VARCHAR2 (50);
  lc_year        VARCHAR2 (10);
  lc_period      VARCHAR2 (10);
  lc_company     VARCHAR2 (50);
  ln_rec_count   NUMBER;
  lc_source_file VARCHAR2 (1000);
  
  lc_exist_file_name VARCHAR2(100);  --v2.0/NAIT-199392 added 
  
  -- Cursor Query to get the Set of Books --
  CURSOR lcu_set_of_books
  IS
    SELECT ---gsb.set_of_books_id,
      gsb.ledger_id,
      gsb.short_name,
      gsb.name,
      SUBSTR(gsb.name,1,2) led_name,
      gsb.currency_code,
      gsb.chart_of_accounts_id
    FROM --gl_sets_of_books gsb
      gl_ledgers gsb
    WHERE gsb.attribute1 = 'Y'
    AND gsb.short_name   = DECODE (p_sob_name, 'ALL', gsb.short_name, p_sob_name )
	order by ledger_id; --v2.0/NAIT-199392
	
  -- Cursor query to get the GL Balances
  CURSOR lcu_gl_balances ( p_set_of_books_id IN NUMBER, p_currency_code IN VARCHAR2, p_period_name IN VARCHAR2, p_coa_id IN NUMBER )
  IS
    SELECT 'Final' version,
      'Actual' scenario,
      gb.period_year YEAR,
      SUBSTR (Gb.period_name, 1, 3) period,
      gld.ledger_id Ledger_id,
      gcc.code_combination_id CCID,
      gb.period_name period_name,
      gb.period_year period_year,
      gcc.segment1 COMPANY,     ---COMPANY
      gcc.segment3 Account,     ---Account
      gcc.segment5 Intercompany, --ICP
      gcc.segment2 Cost_Center, ---CC
      gcc.segment6 LOB,         ---LOB
      gcc.segment4 Location,    ---Location
      gcc.segment7 Future,      ---Future
      SUM((NVL(gb.period_net_dr, 0) + NVL(gb.begin_balance_dr, 0))) - SUM( NVL( gb.period_net_cr, 0) + NVL(gb.begin_balance_cr, 0)) YTD_AMOUNT,
      SUM(NVL (gb.period_net_dr, 0) -NVL (gb.period_net_cr, 0)) periodic_balance,
    --DECODE(gcc.segment1,'1000E','5000E',gcc.segment1) Company_swap
	  DECODE(gcc.segment1,'1100E','5000E',gcc.segment1) Company_swap -- Added for NAIT-127524
    FROM GL_LOOKUPS GLLookups,
      gl_ledger_config_details glcd,
      gl_code_combinations gcc,
      GL_BALANCES GB,
      gl_ledgers gld
    WHERE 1            = 1
    AND gb.ledger_id   = p_set_of_books_id
    AND gb.period_name = p_period_name
    AND gb.ledger_id   =gld.ledger_id
      ----  AND gb.code_combination_id           =21846331
    AND ( ( gb.translated_flag          IN ('Y', 'N')
    AND gb.currency_code                 = p_currency_code )
    OR ( ( gb.translated_flag           IS NULL
    AND gb.currency_code                 = 'STAT' )
    OR ( gb.translated_flag             IS NULL
    AND gb.currency_code                 = p_currency_code ) ) )
    AND gb.actual_flag                   = 'A'
    AND GB.TEMPLATE_ID                  IS NULL
    AND NVL(gb.TRANSLATED_FLAG,'Z') NOT IN ('R')
    AND gcc.code_combination_id          = gb.code_combination_id
    AND gcc.chart_of_accounts_id         = p_coa_id
    AND gcc.segment1                     = NVL (p_company, gcc.segment1)
    AND gcc.summary_flag                 = 'N'
    AND gcc.chart_of_accounts_id         = gld.chart_of_accounts_id
    AND gld.configuration_id             = glcd.configuration_id
    AND glcd.object_type_code            = 'PRIMARY'
    AND glcd.setup_step_code             = 'NONE'
    AND GLLookups.lookup_type            = 'GL_ASF_LEDGER_CATEGORY'
    AND gllookups.lookup_code            = gld.ledger_category_code
    AND (gcc.segment1
      ||gld.short_name <> 1003
      ||'US_USD_P'
    AND gcc.segment1
      ||gld.short_name <> 1001
      ||'CA_CAD_P')
    GROUP BY gld.ledger_id ,
      gcc.code_combination_id ,
      gb.period_name,
      gb.period_year,
      gcc.segment1,---Company
      gcc.segment3,---Account
      gcc.segment5, --ICP
      gcc.segment2,---CC
      gcc.segment6,---LOB
      gcc.segment4,---Location
      gcc.segment7,
    --DECODE(gcc.segment1,'1000E','5000E',gcc.segment1)
	  DECODE(gcc.segment1,'1100E','5000E',gcc.segment1) -- Added for NAIT-127524
    HAVING ((SUM((NVL(gb.period_net_dr, 0) + NVL(gb.begin_balance_dr, 0))) - SUM( NVL( gb.period_net_cr, 0) + NVL(gb.begin_balance_cr, 0))) <> 0
    OR SUM(NVL (gb.period_net_dr, 0)       -NVL (gb.period_net_cr, 0))                                                                      <>0)
  --ORDER BY DECODE(gcc.segment1,'1000E','5000E',gcc.segment1) ;
	ORDER BY DECODE(gcc.segment1,'1100E','5000E',gcc.segment1) ;  -- Added for NAIT-127524
BEGIN
  -- Get application_id
  BEGIN
    SELECT application_id
    INTO ln_appl_id
    FROM fnd_application
    WHERE application_short_name = 'SQLGL';
  EXCEPTION
  WHEN no_data_found THEN
    fnd_file.put_line (fnd_file.LOG, 'Exception raised while fetching the application ID. ' || SQLERRM );
  END;
  x_ret_code := 0;
  BEGIN
    SELECT directory_path
    INTO lc_source_file_path
    FROM dba_directories
    WHERE directory_name = lc_file_path;
    lc_source_file      := lc_source_file_path;
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line (fnd_file.LOG, 'Exception raised while fetching the File Path XXFIN_OUTBOUND. ' || SQLERRM );
  END;
  FOR lr_set_of_books IN lcu_set_of_books
  LOOP
    lc_previous_company := NULL;
    ln_com_count        := 0;
    lc_period_name      := NULL;
    lc_period_status    := 'Y';
    -- Query for fetching period_num for the current period --
    BEGIN
      SELECT LPAD (gp.period_num, 2, 0)
      INTO lc_period_num
      FROM gl_period_statuses gp
      WHERE period_name = p_period_name
        ---AND gp.set_of_books_id = lr_set_of_books.set_of_books_id
      AND gp.ledger_id      = lr_set_of_books.ledger_id
      AND gp.application_id = ln_appl_id;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      fnd_file.put_line (fnd_file.LOG, 'Exception raised while trying to find period number.' );
    END;
    -- Query for fetching flex_value_set_ids for Accounts and Cost Centers --
    BEGIN
      SELECT ffv_cc.flex_value_set_id,
        ffv_ac.flex_value_set_id
      INTO ln_cc_value_set_id,
        ln_acct_value_set_id
      FROM fnd_flex_value_sets ffv_cc,
        fnd_id_flex_segments fsg_cc,
        fnd_flex_value_sets ffv_ac,
        fnd_id_flex_segments fsg_ac
      WHERE fsg_cc.segment_name    = 'Cost Center'
      AND fsg_cc.id_flex_code      ='GL#' -- Added by Vivek on 7-NOV-2013 to fix duplicates records issues SIT02 defect#26312
      AND fsg_cc.flex_value_set_id = ffv_cc.flex_value_set_id
      AND fsg_cc.id_flex_num       = lr_set_of_books.chart_of_accounts_id
      AND fsg_ac.segment_name      = 'Account'
      AND fsg_ac.id_flex_code      ='GL#' -- Added by Vivek on 7-NOV-2013 to fix duplicates records issues SIT02 defect#26312
      AND fsg_ac.flex_value_set_id = ffv_ac.flex_value_set_id
      AND fsg_ac.id_flex_num       = lr_set_of_books.chart_of_accounts_id;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      fnd_file.put_line (fnd_file.LOG, 'Value Set IDs not found for Account and Cost Center. ' || SQLERRM );
    WHEN OTHERS THEN
      fnd_file.put_line (fnd_file.LOG, 'Exception raised while fetching Value Set IDs for Account and Cost Center. ' || SQLERRM );
    END;
    ln_com_count        := 1;
    ln_tot_revenue      := 0;
    ln_net_income       := 0;
    ln_tot_expenses     := 0;
    ln_tot_assets       := 0;
    ln_tot_liability    := 0;
    ln_tot_owner_equity := 0;
    ln_tot_liab_equity  := 0;
    lc_previous_company := NULL;
    ln_rec_count        := 0;
    -- Loop through the gl_balances cursor
    FOR lr_gl_balances IN lcu_gl_balances ( lr_set_of_books.ledger_id, lr_set_of_books.currency_code, p_period_name, lr_set_of_books.chart_of_accounts_id )
    LOOP
      -- fnd_file.put_line (fnd_file.LOG,'lc_previous_company out '||lc_previous_company||'lr_gl_balances.company '||lr_gl_balances.company);
      ----Commented to write 1000E to 5000E(Priyam)
      -- IF (lc_previous_company <> lr_gl_balances.company) THEN
      IF (lc_previous_company <> lr_gl_balances.company_swap) THEN
        --- fnd_file.put_line (fnd_file.LOG,'lc_previous_company inside'||lc_previous_company||'lr_gl_balances.company '||lr_gl_balances.company);
        IF utl_file.is_open (g_lt_file) THEN
          UTL_FILE.fclose (g_lt_file);
        END IF;
        --------------- Call the Common file copy Program to Copy the file to $XXFIN_DATA/ftp/out/hyperion-------------
        lc_source_file_name := lc_source_file_path || '/' || lc_file_name;
        --- lc_dest_file_name   := lc_dest_file_path || '/' || lc_file_name;
        lc_dest_file_name := lc_archive_file_path || '/' || lc_file_name;
        fnd_file.put_line (fnd_file.log, '');
        fnd_file.put_line (fnd_file.log, 'The Created File Name     : ' || lc_source_file_name );
        fnd_file.put_line (fnd_file.LOG, 'The File Copied  Path    : ' || lc_dest_file_name );
        ln_req_id1 := fnd_request.submit_request ('xxfin', 'XXCOMFILCOPY', '', '', FALSE, lc_source_file_name, lc_dest_file_name, NULL, NULL );
        fnd_file.put_line (fnd_file.LOG, '');
        fnd_file.put_line (fnd_file.LOG, 'The File was Copied into ' || lc_dest_file_path || '. Request id : ' || ln_req_id1 );
        COMMIT;
        ----------- Wait for the Common file copy Program to Complete -----------
        lb_req_status1 := fnd_concurrent.wait_for_request (request_id => ln_req_id1, INTERVAL => '2', max_wait => '', phase => lc_phase, status => lc_status, dev_phase => lc_devphase, dev_status => lc_devstatus, MESSAGE => lc_message );
        fnd_file.put_line (fnd_file.LOG, '*************************************************************' );
        ln_com_count := ln_com_count + 1;
        ----  fnd_file.put_line (fnd_file.LOG,'ln_com_count1 '||ln_com_count);
        ln_rec_count        := 0;
        ln_tot_revenue      := 0;
        ln_net_income       := 0;
        ln_tot_expenses     := 0;
        ln_tot_assets       := 0;
        ln_tot_liability    := 0;
        ln_tot_owner_equity := 0;
        ln_tot_liab_equity  := 0;
      END IF;
      -----------GET FILE NAME START-----------------------------------
      IF ln_rec_count = 0 THEN
        ---   fnd_file.put_line (fnd_file.LOG,'ln_rec_count 1 :'||ln_rec_count);
        ----Commented to write 1000E to 5000E(Priyam)
        --- lc_file_name :='LegacyODP_ODPEBS' || lr_gl_balances.company || '_' ||lr_set_of_books.led_name||'_'|| TO_CHAR (TO_DATE (p_period_name, 'MON-YY'), 'Mon') || '_' || TO_CHAR (TO_DATE (p_period_name, 'MON-YY'), 'Mon')|| '_' ||TO_CHAR (TO_DATE (p_period_name, 'MON-YY'), 'YY')||'.txt';
        
		--lc_file_name :='LegacyODP_ODPEBS' || lr_gl_balances.company_swap || '_' ||lr_set_of_books.led_name||'_'|| TO_CHAR (TO_DATE (p_period_name, 'MON-YY'), 'Mon') || '_' || TO_CHAR (TO_DATE (p_period_name, 'MON-YY'), 'Mon')|| '_' ||TO_CHAR (TO_DATE (p_period_name, 'MON-YY'), 'YY')||'.txt'; --Commented v2.0/NAIT-199392 
        lc_file_name :='LegacyODP_ODPEBS' || lr_gl_balances.company_swap || '_' ||trim(lr_set_of_books.led_name)||'_'|| TO_CHAR (TO_DATE (p_period_name, 'MON-YY'), 'Mon') || '_' || TO_CHAR (TO_DATE (p_period_name, 'MON-YY'), 'Mon')|| '_' ||TO_CHAR (TO_DATE (p_period_name, 'MON-YY'), 'YY')||'.txt'; --added v2.0/NAIT-199392

		fnd_file.put_line (fnd_file.LOG, '*************************************************************' );
        fnd_file.put_line (fnd_file.log, 'SOB Name     : ' || lr_set_of_books.short_name );
        ----Commented to write 1000E to 5000E(Priyam)
        ---- fnd_file.put_line (fnd_file.LOG, 'Company     : ' || lr_gl_balances.company );
        fnd_file.put_line (fnd_file.LOG, 'Company     : ' || lr_gl_balances.company_swap );
        fnd_file.put_line (fnd_file.LOG, 'Currency     : ' || lr_set_of_books.currency_code );
        fnd_file.put_line (fnd_file.LOG, 'Period Name  : ' || p_period_name );
        fnd_file.put_line (fnd_file.LOG, '-------------------------------------------------------------' );
        fnd_file.put_line (fnd_file.LOG, 'File Name : ' || lc_file_name);
		
		/*Split Changes v2.0/NAIT-199392 start*/
		lc_exist_file_name :='LegacyODP_ODPEBS' || lr_gl_balances.company_swap || '_US_'|| TO_CHAR (TO_DATE (p_period_name, 'MON-YY'), 'Mon') || '_' || TO_CHAR (TO_DATE (p_period_name, 'MON-YY'), 'Mon')|| '_' ||TO_CHAR (TO_DATE (p_period_name, 'MON-YY'), 'YY')||'.txt';
				
		IF is_file_exist (lc_file_path, lc_exist_file_name)
		THEN
		fnd_file.put_line (fnd_file.LOG,'File exists in US_USD_P ledger. Opening file  ' ||lc_exist_file_name);
			IF NOT UTL_FILE.is_open (g_lt_file) THEN
				 BEGIN
				 g_lt_file    := UTL_FILE.fopen (lc_file_path, lc_exist_file_name, 'a', ln_buffer ); --a append mode
				 lc_file_flag := 'Y';
				 EXCEPTION
				 WHEN OTHERS THEN
				 fnd_file.put_line (fnd_file.LOG, 'Exception raised while Opening the file. ' || SQLERRM );
				 lc_file_flag := 'N';
				 END;
			END IF;
		
		ELSE
		fnd_file.put_line (fnd_file.LOG,'File doesnt exists in US_USD_P ledger. Creating new file  ' ||lc_file_name);
			 IF NOT UTL_FILE.is_open (g_lt_file) THEN
				 BEGIN
				---  fnd_file.put_line (fnd_file.LOG,'IF NOT');
				 g_lt_file    := UTL_FILE.fopen (lc_file_path, lc_file_name, 'w', ln_buffer );
				 lc_file_flag := 'Y';
				 EXCEPTION
				 WHEN OTHERS THEN
				 fnd_file.put_line (fnd_file.LOG, 'Exception raised while Opening the file. ' || SQLERRM );
				 lc_file_flag := 'N';
				 END;
			 END IF;
		END IF;

        /*IF NOT UTL_FILE.is_open (g_lt_file) THEN
          BEGIN
            ---  fnd_file.put_line (fnd_file.LOG,'IF NOT');
            g_lt_file    := UTL_FILE.fopen (lc_file_path, lc_file_name, 'w', ln_buffer );
            lc_file_flag := 'Y';
          EXCEPTION
          WHEN OTHERS THEN
            fnd_file.put_line (fnd_file.LOG, 'Exception raised while Opening the file. ' || SQLERRM );
            lc_file_flag := 'N';
          END;
        END IF; 
		--Split changes v2.0/NAIT-199392 end*/
      END IF;
      -----------GET FILE NAME END-----------------------------------
      -----------GET line record details START-----------------------------------
      BEGIN
        UTL_FILE.put_line (g_lt_file, lr_gl_balances.Ledger_id || '|' || lr_gl_balances.CCID || '|' || lr_gl_balances.period_name || '|' || lr_gl_balances.period_year || '|' || lr_gl_balances.company || '|' || lr_gl_balances.ACCOUNT || '|' || lr_gl_balances.intercompany || '|' || lr_gl_balances.cost_center || '|' || lr_gl_balances.LOB || '|' || lr_gl_balances.Location || '|' || lr_gl_balances.Future || '|' || lr_gl_balances.YTD_AMOUNT || '|' || lr_gl_balances.PERIODIC_BALANCE );
        ln_rec_count := ln_rec_count + 1;
        ------ fnd_file.put_line (fnd_file.LOG,'ln_rec_count-2 '||ln_rec_count);
        ----Commented to write 1000E to 5000E(Priyam)
        --  lc_previous_company := lr_gl_balances.company;
        lc_previous_company := lr_gl_balances.company_swap;
        --  fnd_file.put_line (fnd_file.LOG,'lc_previous_company '||lc_previous_company);
        lc_version  := lr_gl_balances.VERSION;
        lc_scenario := lr_gl_balances.scenario;
        lc_year     := lr_gl_balances.YEAR;
        lc_period   := lr_gl_balances.period;
        lc_company  := lr_gl_balances.company;
      EXCEPTION
      WHEN OTHERS THEN
        ln_error_flag := 1;
        fnd_file.put_line (fnd_file.LOG, 'Exception raised while writing into Text file. ' || SQLERRM );
      END;
      -----------GET line record details END-----------------------------------
    END LOOP;
    IF ln_com_count > 0 AND lc_file_flag = 'Y' THEN
      --- fnd_file.put_line (fnd_file.LOG,'Inside IF');
      IF UTL_FILE.is_open (g_lt_file) THEN
        UTL_FILE.fclose (g_lt_file);
      END IF;
      --------------- Call the Common file copy Program to Copy the file to $XXFIN_DATA/ftp/out/hyperion-------------
      lc_source_file_name := lc_source_file_path || '/' || lc_file_name;
      ---lc_dest_file_name   := lc_dest_file_path || '/' || lc_file_name;
      lc_dest_file_name := lc_archive_file_path || '/' || lc_file_name;
      fnd_file.put_line (fnd_file.log, '');
      fnd_file.put_line (fnd_file.LOG, 'The Created File Name     : ' || lc_source_file_name );
      fnd_file.put_line (fnd_file.LOG, 'The File Copied  Path    : ' || lc_dest_file_name );
      ln_req_id1 := fnd_request.submit_request ('xxfin', 'XXCOMFILCOPY', '', '', FALSE, lc_source_file_name, lc_dest_file_name, NULL, NULL );
      fnd_file.put_line (fnd_file.LOG, '');
      fnd_file.put_line (fnd_file.LOG, 'The File was Copied into ' || lc_dest_file_path || '. Request id : ' || ln_req_id1 );
      COMMIT;
      ----------- Wait for the Common file copy Program to Complete -----------
      lb_req_status1 := fnd_concurrent.wait_for_request (request_id => ln_req_id1, INTERVAL => '2', max_wait => '', phase => lc_phase, status => lc_status, dev_phase => lc_devphase, dev_status => lc_devstatus, MESSAGE => lc_message );
      fnd_file.put_line (fnd_file.LOG, '*************************************************************' );
    END IF;
    fnd_file.put_line (fnd_file.LOG, '');
  END LOOP;
  --------- Call to OD: ZIP Directory Program to archive the files into $XXFIN_ARCHIVE/outbound -------
  --- fnd_file.put_line (fnd_file.log, '*************************************************************' );
  ---fnd_file.put_line (fnd_file.LOG, 'Archiving the files into $XXFIN_ARCHIVE/outbound' );
  --- lc_source_file_name := lc_source_file;
  /*lc_source_file_name := lc_source_file;
  lc_file_name        :='GL_LegacyODP_' || TO_CHAR (to_date (p_period_name, 'MON-YY'), 'Mon') || '_' || TO_CHAR (to_date (p_period_name, 'MON-YY'), 'Mon')|| '_' || TO_CHAR (to_date (p_period_name, 'MON-YY'), 'YY');
  ---lc_dest_file_name := lc_archive_file_path || '/' || lc_file_name;
  lc_dest_file_name := lc_dest_file_path || '/' || lc_file_name;
  fnd_file.put_line (fnd_file.LOG, '');
  fnd_file.put_line (fnd_file.log, 'Input Folder    : ' || lc_source_file_name );
  --- fnd_file.put_line (fnd_file.log, 'The Archived File Path   : ' || lc_dest_file_name );
  fnd_file.put_line (fnd_file.log, 'The MFT File Path   : ' || lc_dest_file_name );
  ln_req_id2 := fnd_request.submit_request ('xxfin', 'XXODDIRZIP', '', '', FALSE, lc_source_file_name, lc_dest_file_name, NULL, NULL );
  COMMIT;
  fnd_file.put_line (fnd_file.log, '');*/
EXCEPTION
WHEN OTHERS THEN
  IF UTL_FILE.is_open (g_lt_file) THEN
    UTL_FILE.fclose (g_lt_file);
  END IF;
  fnd_message.set_name ('XXFIN', 'XX_GL_0006_BAL_EXT_OTHERS');
  fnd_message.set_token ('COL', 'GL Balance');
  lc_error_msg := fnd_message.get;
  fnd_file.put_line (fnd_file.LOG, 'Exception section: ' || SQLERRM);
  x_ret_code := 2;
  xx_com_error_log_pub.log_error (p_program_type => 'CONCURRENT PROGRAM', p_program_name => 'OD: GL Monthly Balance Extract Program', p_program_id => fnd_global.conc_program_id, p_module_name => 'GL', p_error_location => 'Oracle Error ' || SQLERRM, p_error_message_count => ln_msg_cnt + 1, p_error_message_code => 'E', p_error_message => lc_error_msg, p_error_message_severity => 'Major', p_notify_flag => 'N', p_object_type => 'GL Balance Extract' );
END gl_ytd_bal_monthly_extract;
PROCEDURE gl_ytd_wrapper(
    p_sob_name    IN VARCHAR2,
    p_company     IN VARCHAR2,
    p_year        IN VARCHAR2,
    p_period_name IN VARCHAR2)
IS
  v_errbuff VARCHAR2(1000);
  v_retcode NUMBER ;
BEGIN
  xx_gl_legacy_extract_pkg.gl_ytd_bal_monthly_extract(v_errbuff,v_retcode,p_sob_name,p_company,p_year,p_period_name);
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log,'Error encountered gl_ytd_wrapper' );
  v_retcode := 2;
  v_errbuff := 'Error encountered. Please check logs'|| sqlerrm;
END gl_ytd_wrapper;
END xx_gl_legacy_extract_pkg;
/
show error;