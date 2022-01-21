SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
set serveroutput on;
CREATE OR REPLACE PACKAGE BODY XX_FA_MASS_RETIRE_PKG  
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_FA_MASS_RETIRE_PKG.pkb		               |
-- | Description :  Plsql package for Fixed Assets Mass Retirement     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       25-Jan-2013 Paddy Sanjeevi     Initial version           |
-- |1.1       25-Feb-2013 Paddy Sanjeevi     Added PREVIEW logic       |
-- |2.0       28-Aug-2013 Jay Gupta          R12 - Retrofit            |
-- |2.1       25-Nov-2013 Paddy Sanjeevi     Changes made to NBV calc. |
-- |                                         in preview mode.          |
-- |                                         QC Defect - 26624.        |
-- |2.2       12-Dec-2013 Paddy Sanjeevi     QC Defect - 27082         |
-- |2.3       18-Dec-2013 Paddy Sanjeevi     QC Defect - 27082         |
-- |2.4       08-Jan-2014 Paddy Sanjeevi     Defect 27345              | 
-- |2.5       21-Jan-2014 Paddy Sanjeevi     Defect 27379              |
-- |2.6       24-Feb-2014 Paddy Sanjeevi     Defect 28153              |
-- |2.7       05-Nov-2015 Madhu Bolli    	 E3043 - R122 Retrofit Table Schema Removal(defect#36306)|
-- +===================================================================+
AS


-- +====================================================================+
-- | Name        :  purge_proc                                          |
-- | Description :  This procedure is to purge the processed records    |
-- |                in the custom table xx_fa_retire_stg                |
-- | Parameters  :                                                      |
-- +====================================================================+

PROCEDURE purge_proc
IS


CURSOR C1
IS
SELECT rowid drowid
  FROM xx_fa_retire_stg
 WHERE process_Flag=7
   AND creation_date<SYSDATE-30;

i NUMBER:=0;

BEGIN

  FOR cur IN C1 LOOP

    i:=i+1;
    IF i>=5000 THEN
       COMMIT;
       i:=i+1;
    END IF;
   
    DELETE
      FROM xx_fa_retire_stg
     WHERE rowid=cur.drowid;

  END LOOP;
  COMMIT;
EXCEPTION
  WHEN others THEN
    fnd_file.put_line(fnd_file.LOG, 'Error in Purging Processed Records : '||SQLERRM);
END purge_proc;



-- +====================================================================+
-- | Name        :  submit_calculate_gain_loss                          |
-- | Description :  This procedure is submit the seeded program         |
-- |                Calculate Gains and Lsses                           |
-- | Parameters  :                                                      |
-- +====================================================================+

PROCEDURE submit_calculate_gain_loss(p_book_type VARCHAR2)
IS

 ln_request_id	NUMBER;
  v_phase		varchar2(100)   ;
  v_status		varchar2(100)   ;
  v_dphase		varchar2(100)	;
  v_dstatus		varchar2(100)	;
  x_dummy		varchar2(2000) 	;
BEGIN


  ln_request_id:=FND_REQUEST.SUBMIT_REQUEST('OFA','FARET',
					   'Calculate Gains and Losses',NULL,FALSE,
					    p_book_type
					   );

  IF ln_request_id>0 THEN
     COMMIT;
  END IF;

  IF (FND_CONCURRENT.WAIT_FOR_REQUEST(ln_request_id,1,60000,v_phase,
			v_status,v_dphase,v_dstatus,x_dummy))  THEN

       IF v_dphase = 'COMPLETE' THEN
  
	    dbms_output.put_line('success');

       END IF;
  END IF;
EXCEPTION
  WHEN others THEN
    fnd_file.put_line(fnd_file.LOG, 'Error while submitting Calculate Gain/Loss Program : '||SQLERRM);
END submit_calculate_gain_loss;


-- +====================================================================+
-- | Name        :  submit_reports                                      |
-- | Description :  This procedure is to submit retirement   and        |
-- |                exception report                                    |
-- | Parameters  :  p_request_id                                        |
-- +====================================================================+

PROCEDURE submit_reports(p_request_id NUMBER)
IS

  v_addlayout 		boolean;
  lc_boolean            BOOLEAN;
  lc_boolean1           BOOLEAN;
  ln_request_id1	NUMBER;
  ln_request_id2	NUMBER;


  v_phase		varchar2(100)   ;
  v_status		varchar2(100)   ;
  v_dphase		varchar2(100)	;
  v_dstatus		varchar2(100)	;
  x_dummy		varchar2(2000) 	;

BEGIN

  v_addlayout:=FND_REQUEST.ADD_LAYOUT( template_appl_name => 'XXFIN',
	 	                template_code => 'XXFAMRTR', 
				template_language => 'en', 
				template_territory => 'US', 
			        output_format => 'EXCEL');

  IF (v_addlayout) THEN
     fnd_file.put_line(fnd_file.LOG, 'The layout has been submitted');
  ELSE
     fnd_file.put_line(fnd_file.LOG, 'The layout has not been submitted');
  END IF;


  ln_request_id1:=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXFAMRTR',
					   'OD: FA Mass Retirement Report',NULL,FALSE,
					    p_request_id
					  );
  IF ln_request_id1>0 THEN
     fnd_file.put_line(fnd_file.LOG, 'OD FA Mass Retirement Report Request id : '||TO_CHAR(ln_request_id1));
     COMMIT;
  END IF;


  v_addlayout:=FND_REQUEST.ADD_LAYOUT( template_appl_name => 'XXFIN',
	 	                template_code => 'XXFARTRE', 
				template_language => 'en', 
				template_territory => 'US', 
			        output_format => 'EXCEL');

  IF (v_addlayout) THEN
     fnd_file.put_line(fnd_file.LOG, 'The layout has been submitted');
  ELSE
     fnd_file.put_line(fnd_file.LOG, 'The layout has not been submitted');
  END IF;


  ln_request_id2:=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXFARTRE',
					   'OD: FA Mass Retirement Exception Report',NULL,FALSE,
					    p_request_id
					  );
  IF ln_request_id2>0 THEN
     fnd_file.put_line(fnd_file.LOG, 'OD FA Mass Retirement Exception Report Request id : '||TO_CHAR(ln_request_id2));
     COMMIT;
  END IF;

EXCEPTION
  WHEN others THEN
    fnd_file.put_line(fnd_file.LOG, 'When others in Submit_reports :'||sqlerrm);
END submit_reports;



-- +====================================================================+
-- | Name        :  check_duplicate_assets                              |
-- | Description :  This procedure to delete the duplicate assets       |
-- |                for processing in the custom table                  |
-- | Parameters  :  book_type,process_mode, request_id                  |
-- +====================================================================+

PROCEDURE check_duplicate_assets(p_book_type IN VARCHAR2,p_process_mode IN VARCHAR2,p_request_id IN NUMBER)
IS

CURSOR c1
IS
SELECT COUNT(1) cnt,
       asset_id
  FROM xx_fa_retire_stg
 WHERE process_flag=1
   AND book_type_code=p_book_type
   AND request_id=p_request_id
   AND process_mode=p_process_mode
   AND location IS NULL
   AND expense_account IS NULL
 GROUP BY asset_id
 HAVING COUNT(1)>1;

 
CURSOR c2(p_asset_id NUMBER)
IS
SELECT asset_id,process_mode 
  FROM xx_fa_retire_stg
 WHERE process_flag=1
   AND book_type_code=p_book_type
   AND process_mode=p_process_mode
   AND request_id=p_request_id
   AND asset_id=p_asset_id
   AND location IS NULL
   AND expense_account IS NULL;


CURSOR c1_partial
IS
SELECT COUNT(1) cnt,
       asset_id,
       location,
       expense_account
  FROM xx_fa_retire_stg
 WHERE process_flag=1
   AND book_type_code=p_book_type
   AND process_mode=p_process_mode
   AND request_id=p_request_id
   AND location IS NOT NULL
   AND expense_account IS NOT NULL
 GROUP BY asset_id
	 ,location
	 ,expense_account
	 ,book_type_code 
 HAVING COUNT(1)>1;

 
CURSOR c2_partial(p_asset_id NUMBER,p_location VARCHAR2, p_account VARCHAR2)
IS
SELECT asset_id,
       location,
       expense_account,
       book_type_code
  FROM xx_fa_retire_stg
 WHERE process_flag=1
   AND book_type_code=p_book_type
   AND process_mode=p_process_mode
   AND request_id=p_request_id
   AND asset_id=p_asset_id
   AND location=p_location
   AND expense_account=p_account;

   
  i number:=0;    

BEGIN

  -- Setting the process flag=7 for duplicate assets

  FOR cur IN c1 LOOP
    i:=0;
    FOR c in c2(cur.asset_id) LOOP
        i:=i+1;
        IF i>1 THEN

          UPDATE xx_fa_retire_stg
             SET process_flag=7,error_flag='U'
           WHERE process_flag+0=1
             AND asset_id=cur.asset_id
	     AND book_type_code=p_book_type
	     AND process_mode=p_process_mode
	     AND request_id=p_request_id
	     AND location IS NULL
	     AND expense_account IS NULL
             AND ROWNUM<2;  
        
        END IF;    
    
    END LOOP;
  END LOOP;
  COMMIT;

  FOR cur IN c1_partial LOOP
    i:=0;
    FOR c in c2_partial(cur.asset_id,cur.location,cur.expense_account) LOOP
        i:=i+1;
        IF i>1 THEN
        
          UPDATE xx_fa_retire_stg
             SET process_flag=7,error_flag='U'
           WHERE process_flag+0=1
             AND asset_id=cur.asset_id
	     AND book_type_code=p_book_type
	     AND process_mode=p_process_mode
	     AND request_id=p_request_id
	     AND location=cur.location
	     AND expense_account=cur.expense_account
             AND ROWNUM<2;  
        
        END IF;    
    
    END LOOP;
  END LOOP;
  COMMIT;


EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error while checking duplicate assets : '||SQLERRM);  
END check_duplicate_assets;


-- +====================================================================+
-- | Name        :  derive_nbv                                          |
-- | Description :  This procedure to derive net book value             |
-- |                                                                    |
-- | Parameters  :  asset_id, cost,book,request_id                      |
-- +====================================================================+

PROCEDURE derive_nbv( p_asset_id 	IN  NUMBER
		     ,p_cost     	IN  NUMBER
		     ,p_book     	IN  VARCHAR2
		     ,p_request_id 	IN  NUMBER
		    )
IS

  v_nbv NUMBER:=0;
  v_deprn_rsv	NUMBER;
  v_REVAL_RSV                  NUMBER;
  v_YTD_DEPRN                  NUMBER;
  v_YTD_REVAL_EXP              NUMBER;
  v_REVAL_DEPRN_EXP            NUMBER;
  v_DEPRN_EXP                  NUMBER;
  v_REVAL_AMO                  NUMBER;
  v_PROD                       NUMBER;
  v_YTD_PROD                   NUMBER;
  v_LTD_PROD                   NUMBER;
  v_ADJ_COST                   NUMBER;
  v_REVAL_AMO_BASIS            NUMBER;
  v_BONUS_RATE                 NUMBER;
  v_DEPRN_SOURCE_CODE          VARCHAR2(50);
  v_ADJUSTED_FLAG              BOOLEAN;
  v_TRANSACTION_HEADER_ID      NUMBER;
  v_BONUS_DEPRN_RSV            NUMBER;
  v_BONUS_YTD_DEPRN            NUMBER;
  v_BONUS_DEPRN_AMOUNT         NUMBER;
  v_IMPAIRMENT_RSV             NUMBER;
  v_YTD_IMPAIRMENT             NUMBER;
  v_IMPAIRMENT_AMOUNT          NUMBER;
  v_CAPITAL_ADJUSTMENT         NUMBER;
  v_GENERAL_FUND               NUMBER;
  dummy_num 		       number;  
  dummy_char 		       varchar2(10);  
  dummy_bool 		       boolean;
  l_impairment_rsv             number;
  v_deprn_open_period 	       NUMBER;   
  v_derived_cost_retired       NUMBER;	 
  v_factor		       NUMBER;      
  v_prorate_accum_deprn	       NUMBER;
  v_prorate_curm_deprn	       NUMBER;
  v_nbv_retired		       NUMBER;
  v_gnls_amnt   	       NUMBER;
  v_prorate_pct			NUMBER;
  v_asset_cost_retired		NUMBER;
  v_rtd_year			NUMBER;
  v_cur_year			NUMBER;
  v_cur_open_date		DATE;
  v_bkdtd_months		NUMBER;
  V_CUR_PNUM			NUMBER;
  V_RTD_PNUM			NUMBER;
  v_rtd_deprn_amnt		NUMBER;
  v_rtd_period			VARCHAR2(20);
  v_current_period		VARCHAR2(20);
  -- V2.0, Declare record type
  lrec_fa_log FA_API_TYPES.log_level_rec_type;

  CURSOR C1 IS
  SELECT asset_id,
       retirement_date,
       fa_current_cost,
       current_units,
       life_in_months,
       nbv,
       book_type_code,
       NVL(cost_of_removal,0) cost_of_removal,
       NVL(pos_to_be,0) pos_to_be,
       sum(units_retired) units_retired,
       sum(cost_to_be_retired) cost_retired
  FROM xx_fa_retire_stg
 WHERE request_id=p_request_id
   AND asset_id=p_asset_id
   AND process_flag=1
   AND process_mode='PREVIEW'
   AND book_type_code=p_book
   AND error_flag='N'
 GROUP BY asset_id,
	  retirement_date,
	  fa_current_cost,
	  current_units,
          life_in_months,
	  nbv,
          book_type_code,
          NVL(cost_of_removal,0),
	  NVL(pos_to_be,0);


BEGIN

  fa_query_balances_pkg.query_balances(
	X_asset_id => p_asset_id,
	X_book => p_book,
	X_period_ctr => 0,
	X_dist_id => 0,
	X_run_mode => 'STANDARD',
	X_cost => dummy_num,
	X_deprn_rsv => v_deprn_rsv,
	X_reval_rsv => v_reval_rsv,
	X_ytd_deprn => v_ytd_deprn,
	X_ytd_reval_exp => dummy_num,
	X_reval_deprn_exp => dummy_num,
	X_deprn_exp => dummy_num,
	X_reval_amo => dummy_num,
	X_prod => dummy_num,
	X_ytd_prod => v_ytd_prod,
	X_ltd_prod => v_ltd_prod,
	X_adj_cost => dummy_num,
	X_reval_amo_basis => dummy_num,
	X_bonus_rate => dummy_num,
	X_deprn_source_code => dummy_char,
	X_adjusted_flag => dummy_bool,
	X_transaction_header_id => -1,
	X_bonus_deprn_rsv => v_bonus_deprn_rsv,
	X_bonus_ytd_deprn => v_bonus_ytd_deprn,
	X_bonus_deprn_amount => dummy_num,
        X_impairment_rsv => l_impairment_rsv,
        X_ytd_impairment => dummy_num,
        X_impairment_amount => dummy_num,
		-- V2.0, Added below new Parameters as part since API has been changed in R12
		X_CAPITAL_ADJUSTMENT  => dummy_num, -- OUT NOCOPY NUMBER,  -- Bug 6666666
        X_GENERAL_FUND     => dummy_num,    -- OUT NOCOPY NUMBER,
        X_MRC_SOB_TYPE_CODE => 'X',         -- IN VARCHAR2, -- V2.0, if passing reporting SOB then SOB is required
        X_SET_OF_BOOKS_ID  => dummy_num,    -- IN NUMBER,  
        p_log_level_rec    => lrec_fa_log   -- IN FA_API_TYPES.log_level_rec_type -- Bug 6666666
		);


   FOR CUR IN C1 LOOP

     v_derived_cost_retired	:=0;
     v_factor			:=0;
     v_prorate_accum_deprn	:=0;
     v_prorate_curm_deprn	:=0;
     v_nbv_retired		:=0;
     v_gnls_amnt		:=0;
     v_asset_cost_retired	:=0;
     v_rtd_deprn_amnt		:=0;
     v_rtd_period		:=NULL;

     BEGIN
       SELECT dp.period_name
	 INTO v_current_period
         from fa_deprn_periods dp,
              fa_deprn_periods dp2,
              fa_deprn_periods dp3,
              fa_book_controls bc
        where dp.book_type_code = cur.book_type_code
          and  dp.period_close_date is null    
          and  dp2.book_type_code(+) = bc.distribution_source_book
          and  dp2.period_counter(+) = bc.last_mass_copy_period_counter
          and  dp3.book_type_code(+) = bc.book_type_code
	  and  dp3.period_counter(+) = bc.last_purge_period_counter
	  and  bc.book_type_code = cur.book_type_code;
 
       BEGIN
         SELECT start_date
	   INTO v_cur_open_date
           FROM fa_calendar_periods
          WHERE calendar_type='OD_ALL_MONTH'
            AND period_name=v_current_period;
       EXCEPTION
         WHEN others THEN
	   v_cur_open_date:=NULL;
       END;
     EXCEPTION
       WHEN others THEN
	 v_current_period:=NULL;
     END;


     IF cur.retirement_date<v_cur_open_date THEN

	-- Begin -- Defect 28153
  
        BEGIN
          SELECT period_name
	    INTO v_rtd_period
  	    FROM fa_calendar_periods
  	   WHERE calendar_type='OD_ALL_MONTH'
             AND cur.retirement_date BETWEEN START_DATE AND END_DATE;
        EXCEPTION
          WHEN others THEN
	    v_rtd_period:=NULL;
        END;

    
	  SELECT SUM(deprn_amount)
	    INTO v_rtd_deprn_amnt
	    FROM fa_deprn_summary
	   WHERE asset_id=cur.asset_id
             AND book_type_code=cur.book_type_code	
	     AND period_counter IN (SELECT period_counter
				     from fa_deprn_periods
				    where book_type_code=cur.book_type_code
				      and calendar_period_open_date>=(select start_date
						                        from fa_calendar_periods
						           	       WHERE calendar_type='OD_ALL_MONTH'
							                 and period_name=v_rtd_period)
				   );
     END IF;

       BEGIN
         SELECT NVL(SUM(deprn_amount),0)
	   INTO v_deprn_open_period
  	   FROM FA_DEPRN_SUMMARY ds
          WHERE asset_id=p_asset_id 
     	    AND book_type_code=p_book
	    AND period_counter in (select dp.period_counter
				         from  fa_deprn_periods dp,
					       fa_deprn_periods dp2,
				               fa_deprn_periods dp3,
				               fa_book_controls bc
				        where  dp.book_type_code = p_book
					  and  dp.period_close_date is null	
				          and  dp2.book_type_code(+) = bc.distribution_source_book
					  and  dp2.period_counter(+) = bc.last_mass_copy_period_counter
					  and  dp3.book_type_code(+) = bc.book_type_code
					  and  dp3.period_counter(+) = bc.last_purge_period_counter
					  and  bc.book_type_code = p_book);
       EXCEPTION
         WHEN OTHERS THEN
           fnd_file.put_line(fnd_file.LOG, 'Error in getting the depreciation amount for open period');
           v_deprn_open_period :=0;
       END;

       IF cur.cost_retired IS NOT NULL THEN

          v_derived_cost_retired:=cur.cost_retired;

	    BEGIN
              v_prorate_pct :=cur.cost_retired/cur.fa_current_cost;
	    EXCEPTION
	      WHEN others THEN
	       v_prorate_pct:=0;
	    END;

       ELSIF cur.units_retired IS NOT NULL THEN

  	  v_derived_cost_retired:=(cur.units_retired/cur.current_units)*cur.fa_current_cost;

	    BEGIN
              v_prorate_pct :=cur.units_retired/cur.current_units;
            EXCEPTION
	      WHEN others THEN
	       v_prorate_pct:=0;
	    END;

       END IF;
  
       v_factor:=v_derived_cost_retired/cur.fa_current_cost;

       v_prorate_accum_deprn:=v_factor*v_deprn_rsv;

       IF cur.retirement_date<v_cur_open_date THEN

          v_prorate_curm_deprn:=v_rtd_deprn_amnt;

       ELSE

          v_prorate_curm_deprn:=ROUND((v_factor*v_deprn_open_period),2);

       END IF;

       v_nbv_retired:=v_derived_cost_retired-ROUND(v_prorate_accum_deprn,2)+v_prorate_curm_deprn;

       v_gnls_amnt   :=NVL(cur.pos_to_be,0)-NVL(cur.cost_of_removal,0)-NVL(v_nbv_retired,0);

       v_nbv:=(p_cost - v_deprn_rsv - nvl(l_impairment_rsv,0));

       UPDATE xx_fa_retire_stg
         SET nbv=v_nbv,
	     nbv_retired=v_nbv_retired,
	     gain_loss_amount=v_gnls_amnt
	--   ,asset_cost_retired=v_asset_cost_retired
       WHERE asset_id=p_asset_id
         AND request_id+0=p_request_id
         AND book_type_code=p_book; 

   -- End -- Defect 28153

   END LOOP;
 
EXCEPTION
  WHEN others THEN
    fnd_file.put_line(fnd_file.LOG, 'Error while deriving NBV for the asset :'||p_asset_id|| ','||SQLERRM);
END derive_nbv;


-- +====================================================================+
-- | Name        :  xx_retire_nd                                        |
-- | Description :  This procedure to call retirement api for an asset  |
-- |                                                                    |
-- | Parameters  :  asset_id,request_id, book_type, retire_conv,rtd_date|
-- |                rtr_units, rtr_cost, rts_pos, rtr_type, sold_to,    |
-- |                comments, cost removal                              |
-- +====================================================================+

PROCEDURE xx_retire_nd( p_asset_id 	IN NUMBER,
			p_request_id  IN NUMBER,
			p_book_type   IN VARCHAR2,
			p_retr_conv	IN VARCHAR2,
			p_rtr_date	IN DATE,
			p_rtr_units	IN NUMBER,
			p_rtr_cost	IN NUMBER,
			p_rtr_pos	IN NUMBER,
			p_rtr_type	IN VARCHAR2,
			p_sold_to	IN VARCHAR2,			  
			p_comments	IN VARCHAR2,
			p_cost_removal  IN NUMBER
		      )

IS

 api_error EXCEPTION;  

 l_trans_rec 		FA_API_TYPES.trans_rec_type;
 l_dist_trans_rec 	FA_API_TYPES.trans_rec_type;
 l_asset_hdr_rec 	FA_API_TYPES.asset_hdr_rec_type;
 l_asset_retire_rec 	FA_API_TYPES.asset_retire_rec_type;
 l_asset_dist_tbl 	FA_API_TYPES.asset_dist_tbl_type;
 l_subcomp_tbl 		FA_API_TYPES.subcomp_tbl_type;
 l_inv_tbl 		FA_API_TYPES.inv_tbl_type;

 l_user_id number 	:= fnd_global.user_id;

 l_api_version 		NUMBER 		:= 1;
 l_init_msg_list 	VARCHAR2(1) 	:= FND_API.G_FALSE;
 l_commit 		VARCHAR2(1) 	:= FND_API.G_TRUE;
 l_validation_level 	NUMBER 		:= FND_API.G_VALID_LEVEL_FULL;
 l_calling_fn 		VARCHAR2(80) 	:= 'Retirement test wrapper';
 l_return_status 	VARCHAR2(1) 	:= FND_API.G_FALSE;
 l_msg_count 		NUMBER 		:= 0; 
 l_msg_data 		VARCHAR2(512); 

 l_count 		NUMBER;
 l_request_id 		NUMBER;
 
 i NUMBER := 0;
 
 temp_str 		VARCHAR2(512);
 mesg_count 		NUMBER;
 l_mesg 		VARCHAR2(4000);
 
 

BEGIN

  fa_srvr_msg.init_server_message;
  fa_debug_pkg.set_debug_flag(debug_flag => 'YES');

  l_request_id						:= fnd_global.conc_request_id;
  l_trans_rec.who_info.last_updated_by 	 		:=l_user_id;
  l_trans_rec.who_info.last_update_login 		:= -1; 
  l_trans_rec.transaction_name		 		:=SUBSTR(p_comments,1,30);

  l_trans_rec.who_info.last_update_date 		:= sysdate;
  l_trans_rec.who_info.creation_date 	 		:= l_trans_rec.who_info.last_update_date;
  l_trans_rec.who_info.created_by 	 		:= l_trans_rec.who_info.last_updated_by;
 
  l_trans_rec.transaction_type_code 			:= NULL; -- this will be determined inside API
  l_trans_rec.transaction_date_entered 			:= NULL;
 
  l_asset_hdr_rec.asset_id 				:= p_asset_id;
  l_asset_hdr_rec.book_type_code 			:= p_book_type;
  l_asset_hdr_rec.period_of_addition 			:= NULL;

  l_asset_retire_rec.retirement_prorate_convention 	:= p_retr_conv;
  l_asset_retire_rec.date_retired 			:= p_rtr_date; 
  l_asset_retire_rec.units_retired			:= p_rtr_units;
  l_asset_retire_rec.cost_retired 			:= p_rtr_cost; 
  l_asset_retire_rec.proceeds_of_sale 			:= p_rtr_pos;
  l_asset_retire_rec.cost_of_removal 			:= p_cost_removal;
  l_asset_retire_rec.retirement_type_code 		:= p_rtr_type;
  l_asset_retire_rec.trade_in_asset_id 			:= NULL;
  l_asset_retire_rec.calculate_gain_loss 		:= FND_API.G_FALSE;

  l_asset_dist_tbl.delete;
 
  FA_RETIREMENT_PUB.do_retirement
 		( p_api_version 	=> l_api_version
		 ,p_init_msg_list 	=> l_init_msg_list
		 ,p_commit 		=> l_commit
		 ,p_validation_level 	=> l_validation_level
		 ,p_calling_fn 		=> l_calling_fn
		 ,x_return_status 	=> l_return_status
		 ,x_msg_count 		=> l_msg_count
		 ,x_msg_data 		=> l_msg_data
		 ,px_trans_rec 		=> l_trans_rec
		 ,px_dist_trans_rec 	=> l_dist_trans_rec
		 ,px_asset_hdr_rec 	=> l_asset_hdr_rec
		 ,px_asset_retire_rec 	=> l_asset_retire_rec
		 ,p_asset_dist_tbl 	=> l_asset_dist_tbl
		 ,p_subcomp_tbl 	=> l_subcomp_tbl
		 ,p_inv_tbl 		=> l_inv_tbl
	       );
 
  fnd_file.put_line(fnd_file.LOG, 'Return Status :'||l_return_status);

  IF l_return_status <> 'S' THEN

     RAISE api_error;

  ELSE
   
     UPDATE xx_fa_retire_stg
        SET retirement_id=l_asset_retire_rec.retirement_id
      WHERE asset_id=p_asset_id
        AND request_id+0=p_request_id
        AND book_type_code=p_book_type;
     COMMIT;

  END IF;
EXCEPTION
  WHEN api_error THEN
    fa_srvr_msg.add_message( calling_fn => l_calling_fn,
		  	     name 	=> 'FA_SHARED_PROGRAM_FAILED',
		  	     token1 	=> 'PROGRAM',
			     value1 	=> l_calling_fn);

    mesg_count := fnd_msg_pub.count_msg;

    IF (mesg_count > 0) THEN
        temp_str := fnd_msg_pub.get(fnd_msg_pub.G_FIRST, fnd_api.G_FALSE);
	l_mesg:=temp_str; 
        FOR I in 1..(mesg_count -1) LOOP
  	  temp_str := fnd_msg_pub.get(fnd_msg_pub.G_NEXT, fnd_api.G_FALSE);
	  IF LENGTH(l_mesg)<4000 THEN
     	     l_mesg:=l_mesg||','||temp_str;
          END IF;
        END LOOP;
    END IF;
    ROLLBACK;
    UPDATE xx_fa_retire_stg
       SET error_flag='Y',
	   error_message=error_message||','||l_mesg
     WHERE asset_id=p_asset_id
       AND request_id+0=p_request_id
       AND book_type_code=p_book_type;
    COMMIT;
 WHEN others THEN
   fnd_file.put_line(fnd_file.LOG, 'When others in xx_retire_nd :'||SQLERRM);
END xx_retire_nd;


-- +====================================================================+
-- | Name        :  xx_retire_partial                                   |
-- | Description :  This procedure to partially retire asset by calling |
-- |                retirement api                                      |
-- | Parameters  :  request_id, book_type, process_mode                 |
-- +====================================================================+

PROCEDURE xx_retire_partial(p_request_id    	IN NUMBER,
 		  	    p_book_type   	IN VARCHAR2,
			    p_process_mode	IN VARCHAR2
  		           )

IS

CURSOR C1
IS
SELECT DISTINCT 
       asset_id,
       retirement_type,
       retirement_date,
       pos_to_be,
       retire_convention,
       sold_to,
       cost_of_removal,
       comments
  FROM xx_fa_retire_Stg
 WHERE request_id=p_request_id
   AND book_type_code=p_book_type
   AND process_mode=p_process_mode
   AND retirement_process='DISTRIBUTION'
   AND distribution_id IS NOT NULL
   AND NVL(error_flag,'N')='N';


CURSOR C2(p_asset_id NUMBER)
IS
SELECT distribution_id,
       units_retired
  FROM xx_fa_retire_stg
 WHERE asset_id=p_asset_id
   AND request_id+0=p_request_id
   AND book_type_code=p_book_type
   AND process_mode=p_process_mode
   AND retirement_process='DISTRIBUTION'
   AND distribution_id IS NOT NULL
   AND NVL(error_flag,'N')='N';


 api_error EXCEPTION;  

 l_trans_rec 		FA_API_TYPES.trans_rec_type;
 l_dist_trans_rec 	FA_API_TYPES.trans_rec_type;
 l_asset_hdr_rec 	FA_API_TYPES.asset_hdr_rec_type;
 l_asset_retire_rec 	FA_API_TYPES.asset_retire_rec_type;
 l_asset_dist_tbl 	FA_API_TYPES.asset_dist_tbl_type;
 l_subcomp_tbl 		FA_API_TYPES.subcomp_tbl_type;
 l_inv_tbl 		FA_API_TYPES.inv_tbl_type;

 l_user_id number 	:= fnd_global.user_id;

 l_api_version 		NUMBER 		:= 1;
 l_init_msg_list 	VARCHAR2(1) 	:= FND_API.G_FALSE;
 l_commit 		VARCHAR2(1) 	:= FND_API.G_TRUE;
 l_validation_level 	NUMBER 		:= FND_API.G_VALID_LEVEL_FULL;
 l_calling_fn 		VARCHAR2(80) 	:= 'Retirement test wrapper';
 l_return_status 	VARCHAR2(1) 	:= FND_API.G_FALSE;
 l_msg_count 		NUMBER 		:= 0; 
 l_msg_data 		VARCHAR2(512); 

 l_count 		NUMBER;
 l_request_id 		NUMBER;
 
 i NUMBER := 0;
 
 temp_str 		VARCHAR2(512);
 mesg_count 		NUMBER;
 l_mesg 		VARCHAR2(4000);
 
 j NUMBER:=0;
 l_total_units		NUMBER:=0;

BEGIN

  FOR c IN C1 LOOP

    fa_srvr_msg.init_server_message;
    fa_debug_pkg.set_debug_flag(debug_flag => 'YES');

    l_request_id					:= fnd_global.conc_request_id;
    l_trans_rec.who_info.last_updated_by 	 	:=l_user_id;
    l_trans_rec.who_info.last_update_login 		:= -1; 
    l_trans_rec.who_info.last_update_date 		:= sysdate;
    l_trans_rec.who_info.creation_date 	 		:= l_trans_rec.who_info.last_update_date;
    l_trans_rec.who_info.created_by 	 		:= l_trans_rec.who_info.last_updated_by;
    l_trans_rec.transaction_type_code 			:= NULL; -- this will be determined inside API
    l_trans_rec.transaction_date_entered 		:= NULL;
    l_trans_rec.transaction_name		 	:=SUBSTR(c.comments,1,30);

    l_asset_hdr_rec.asset_id 				:= c.asset_id;
    l_asset_hdr_rec.book_type_code 			:= p_book_type;
    l_asset_hdr_rec.period_of_addition 			:= NULL;

    l_asset_retire_rec.retirement_prorate_convention 	:= c.retire_convention;
    l_asset_retire_rec.date_retired 			:= c.retirement_date; 

    l_asset_retire_rec.proceeds_of_sale 		:= c.pos_to_be;
    l_asset_retire_rec.sold_to		 		:= c.sold_to;
    l_asset_retire_rec.cost_of_removal 			:= c.cost_of_removal;
    l_asset_retire_rec.retirement_type_code 		:= c.retirement_type;
    l_asset_retire_rec.trade_in_asset_id 		:= NULL;
    l_asset_retire_rec.calculate_gain_loss 		:= FND_API.G_FALSE;

    j:=0;
    l_total_units:=0;
    l_asset_dist_tbl.delete;

    FOR cur IN C2(c.asset_id) LOOP

	j:=j+1;

	l_total_units:=l_total_units+cur.units_retired;

	l_asset_dist_tbl(j).distribution_id 		:= cur.distribution_id;
	l_asset_dist_tbl(j).transaction_units 		:= cur.units_retired*-1;
	l_asset_dist_tbl(j).units_assigned 		:= null;
	l_asset_dist_tbl(j).assigned_to 		:= null;
	l_asset_dist_tbl(j).expense_ccid 		:= null;
	l_asset_dist_tbl(j).location_ccid 		:= null;
 
    END LOOP;
 
    l_asset_retire_rec.units_retired			:= l_total_units;
    
    BEGIN

      FA_RETIREMENT_PUB.do_retirement
 		( p_api_version 	=> l_api_version
		 ,p_init_msg_list 	=> l_init_msg_list
		 ,p_commit 		=> l_commit
		 ,p_validation_level 	=> l_validation_level
		 ,p_calling_fn 		=> l_calling_fn
		 ,x_return_status 	=> l_return_status
		 ,x_msg_count 		=> l_msg_count
		 ,x_msg_data 		=> l_msg_data
		 ,px_trans_rec 		=> l_trans_rec
		 ,px_dist_trans_rec 	=> l_dist_trans_rec
		 ,px_asset_hdr_rec 	=> l_asset_hdr_rec
		 ,px_asset_retire_rec 	=> l_asset_retire_rec
		 ,p_asset_dist_tbl 	=> l_asset_dist_tbl
		 ,p_subcomp_tbl 	=> l_subcomp_tbl
		 ,p_inv_tbl 		=> l_inv_tbl
	       );

      fnd_file.put_line(fnd_file.LOG, 'Return Status :'||l_return_status);

      IF l_return_status <> 'S' THEN
 
         fnd_file.put_line(fnd_file.LOG, 'API RETURNED FAIL');
         RAISE api_error;

      ELSE

         fnd_file.put_line(fnd_file.LOG, 'API RETURNED SUCCESS');
     
         UPDATE xx_fa_retire_stg
  	    SET retirement_id=l_asset_retire_rec.retirement_id
          WHERE asset_id=c.asset_id
            AND request_id+0=p_request_id
            AND book_type_code=p_book_type
	    AND process_mode=p_process_mode;
         COMMIT;

      END IF;

    EXCEPTION
      WHEN api_error THEN
        fa_srvr_msg.add_message( calling_fn => l_calling_fn,
	 	  	         name 	    => 'FA_SHARED_PROGRAM_FAILED',
		  	         token1     => 'PROGRAM',
			         value1     => l_calling_fn);

        mesg_count := fnd_msg_pub.count_msg;

        IF (mesg_count > 0) THEN
           temp_str := fnd_msg_pub.get(fnd_msg_pub.G_FIRST, fnd_api.G_FALSE);
	   l_mesg:=temp_str; 

           FOR I in 1..(mesg_count -1) LOOP
             temp_str := fnd_msg_pub.get(fnd_msg_pub.G_NEXT, fnd_api.G_FALSE);
	     IF LENGTH(l_mesg)<4000 THEN
     	        l_mesg:=l_mesg||','||temp_str;
             END IF;
           END LOOP;
        END IF;
        ROLLBACK;
        UPDATE xx_fa_retire_stg
           SET error_flag='Y',
	       error_message=error_message||','||l_mesg
         WHERE asset_id=c.asset_id
           AND request_id+0=p_request_id
           AND book_type_code=p_book_type
	   AND process_mode=p_process_mode;
        COMMIT;
      WHEN others THEN
        fnd_file.put_line(fnd_file.LOG, 'When others in xx_retire_nd :'||SQLERRM);
    END;
  END LOOP;
EXCEPTION
  WHEN others THEN
    fnd_file.put_line(fnd_file.LOG, 'When others in xx_retire_partial :'||SQLERRM);
END xx_retire_partial;

-- +====================================================================+
-- | Name        :  Asset_retirement                                    |
-- | Description :  This procedure to process assets in the custom table|
-- |                xx_fa_retire_stg for retirements                    |
-- | Parameters  :  errbuf, retcode, process_mode, book_type            |
-- +====================================================================+


PROCEDURE asset_retirement   ( x_errbuf      	OUT NOCOPY VARCHAR2
                              ,x_retcode     	OUT NOCOPY VARCHAR2
			      ,p_process_mode	IN  VARCHAR2
			      ,p_book_type	IN  VARCHAR2
  		             )
IS

CURSOR c_get_context_date
IS
SELECT greatest(calendar_period_open_date,
       least(sysdate, calendar_period_close_date)),
       calendar_period_open_date
  FROM fa_deprn_periods
 WHERE book_type_code = p_book_type
   AND period_close_date IS NULL;


CURSOR C1
IS
SELECT asset_id,
       NVL(location_id,-1) location_id
  FROM xx_fa_retire_stg
 WHERE process_flag=1 
   AND book_type_code=p_book_type
   AND process_mode=p_process_mode
   AND location IS NULL;


CURSOR c_asset(p_asset_id NUMBER,p_book_type VARCHAR2)
IS
SELECT a.asset_id,    
       a.asset_number,                            
       a.description,  
       a.current_units,                              
       a.attribute6 legacy_asset_id,
       a.attribute10 tax_asset_id,
       b.book_type_code,      
       cc.segment1 company,                                
       cc.segment4 building,                                
       cc.segment2 costcenter,    
       cc.segment6 lob,    
       fb.date_placed_in_service,                                
       fb.life_in_months,  
       fb.prorate_convention_code,  
       fb.cost,                                
       fb.deprn_method_code,
       ds.deprn_amount,    
       ds.ytd_deprn,                                
       ds.deprn_reserve,                                
       fcat.segment1 Major,                                
       fcat.segment2 Minor,                                
       fcat.segment3 Subminor                            
  FROM gl_code_combinations cc,
       fa_categories_b fcat,
       FA_DEPRN_SUMMARY ds,                                   
       fa_books fb,    
       fa_distribution_history b,    
       fa_additions a                                
 WHERE a.asset_id=p_asset_id
   AND b.asset_id=a.asset_id
   AND b.date_ineffective is null                          
   AND b.book_type_code=p_book_type
   AND fb.asset_id=b.asset_id
   AND fb.book_type_code=b.book_type_code
   AND fb.date_ineffective IS NULL
   AND ds.asset_id=fb.asset_id                                
   AND ds.book_type_code=fb.book_type_code                        
   AND DS.PERIOD_COUNTER = (SELECT max(DS1.PERIOD_COUNTER)                
                              FROM FA_DEPRN_SUMMARY DS1                
                             WHERE DS1.ASSET_ID=DS.ASSET_ID                
                               AND DS1.BOOK_TYPE_CODE = DS.BOOK_TYPE_CODE)
   AND fcat.category_id=a.asset_category_id 
   AND cc.code_combination_id=b.code_combination_id
   AND fcat.segment1 IN (SELECT flex_value
               FROM fnd_flex_values b,
                    Fnd_flex_value_sets a
              WHERE flex_value_set_name='XX_FA_REVAL_CATEGORY'
                AND b.flex_value_Set_id=a.flex_value_set_id
                AND b.enabled_flag='Y');


CURSOR C1_loc 
IS
SELECT asset_id,
       NVL(location_id,-1) location_id
  FROM xx_fa_retire_stg
 WHERE process_flag=1 
   AND book_type_code=p_book_type
   AND process_mode=p_process_mode
   AND location IS NOT NULL;

CURSOR c_asset_loc(p_asset_id NUMBER,p_book_type VARCHAR2,p_location_id NUMBER)
IS
SELECT a.asset_id,    
       a.asset_number,                            
       a.description,  
       a.current_units,                              
       a.attribute6 legacy_asset_id,
       a.attribute10 tax_asset_id,
       b.book_type_code,      
       b.location_id,                          
       cc.segment1 company,                                
       cc.segment4 building,                                
       cc.segment2 costcenter,    
       cc.segment6 lob,    
       fb.date_placed_in_service,                                
       fb.life_in_months,  
       fb.prorate_convention_code,  
       fb.cost,                                
       fb.deprn_method_code,
       ds.deprn_amount,    
       ds.ytd_deprn,                                
       ds.deprn_reserve,                                
       fcat.segment1 Major,                                
       fcat.segment2 Minor,                                
       fcat.segment3 Subminor                            
  FROM gl_code_combinations cc,
       fa_categories_b fcat,
       FA_DEPRN_SUMMARY ds,                                   
       fa_books fb,    
       fa_distribution_history b,    
       fa_additions a                                
 WHERE a.asset_id=p_asset_id
   AND b.asset_id=a.asset_id
   AND b.date_ineffective is null                          
   AND b.book_type_code=p_book_type
   AND b.location_id=p_location_id
   AND fb.asset_id=b.asset_id
   AND fb.book_type_code=b.book_type_code
   AND fb.date_ineffective IS NULL
   AND ds.asset_id=fb.asset_id                                
   AND ds.book_type_code=fb.book_type_code                        
   AND DS.PERIOD_COUNTER = (SELECT max(DS1.PERIOD_COUNTER)                
                              FROM FA_DEPRN_SUMMARY DS1                
                             WHERE DS1.ASSET_ID=DS.ASSET_ID                
                               AND DS1.BOOK_TYPE_CODE = DS.BOOK_TYPE_CODE)
   AND fcat.category_id=a.asset_category_id 
   AND cc.code_combination_id=b.code_combination_id
   AND fcat.segment1 IN (SELECT flex_value
               FROM fnd_flex_values b,
                    Fnd_flex_value_sets a
              WHERE flex_value_set_name='XX_FA_REVAL_CATEGORY'
                AND b.flex_value_Set_id=a.flex_value_set_id
                AND b.enabled_flag='Y');



CURSOR c_derived_id_partial(p_request_id NUMBER)
IS
SELECT asset_id,
       rowid drowid
  FROM xx_fa_retire_stg
 WHERE process_flag=1 
   AND book_type_code=p_book_type
   AND process_mode=p_process_mode
   AND request_id+0=p_request_id
   AND retirement_process='DISTRIBUTION'
   AND distribution_id IS NULL;


CURSOR c_derive_id(p_request_id NUMBER)
IS
SELECT asset_id,
       location,
       expense_account,
       rowid drowid
  FROM xx_fa_retire_stg
 WHERE process_flag=1 
   AND book_type_code=p_book_type
   AND process_mode=p_process_mode
   AND request_id+0=p_request_id
   AND location IS NOT NULL
   AND expense_account IS NOT NULL;


CURSOR c_nbv(p_request_id NUMBER)
IS
SELECT DISTINCT 
       asset_id,
       fa_current_cost,
       book_type_code
  FROM xx_fa_retire_stg
 WHERE request_id=p_request_id
   AND book_type_code=p_book_type
   AND process_mode='PREVIEW'
   AND error_flag='N';


CURSOR c_retire(p_request_id NUMBER)
IS
SELECT *
  FROM xx_fa_retire_stg
 WHERE process_flag=1 
   AND book_type_code=p_book_type
   AND process_mode=p_process_mode
   AND request_id+0=p_request_id
   AND retirement_process IS NULL
   AND NVL(error_flag,'N')='N';


CURSOR c_retire_update(p_request_id NUMBER)
IS
SELECT *
  FROM xx_fa_retire_stg
 WHERE process_flag=1 
   AND book_type_code=p_book_type
   AND process_mode=p_process_mode
   AND request_id+0=p_request_id
   AND NVL(error_flag,'N')='N'
   AND retirement_id IS NOT NULL;

CURSOR c_check_preview(p_request_id NUMBER,p_book_type VARCHAR2)
IS
SELECT a.asset_id,
       NVL(a.location,'X') location,
       NVL(a.expense_account,'X') expense_account
  FROM xx_fa_retire_stg a
 WHERE a.request_id=p_request_id
   AND a.process_mode='PREVIEW'
   AND a.book_type_code=p_book_type
   AND a.process_flag=1
   AND EXISTS (SELECT 'x'
		 FROM xx_fa_retire_stg
		WHERE asset_id=a.asset_id
		  AND process_mode=a.process_mode
		  AND book_type_code=p_book_type
		  AND process_Flag+0=4
		  AND NVL(location,'X')=NVL(a.location,'X')
		  AND NVL(expense_account,'X')=NVL(a.expense_account,'X'));



CURSOR c_check_run(p_request_id NUMBER,p_book_type VARCHAR2)
IS
SELECT a.asset_id,
       NVL(a.location,'X') location,
       NVL(a.expense_account,'X') expense_account
  FROM xx_fa_retire_stg a
 WHERE a.request_id=p_request_id
   AND a.process_flag=1
   AND a.process_mode='RUN'
   AND a.book_type_code=p_book_type
   AND NOT EXISTS (SELECT 'x'
		 FROM xx_fa_retire_stg
		WHERE asset_id=a.asset_id
		  AND process_mode='PREVIEW'
		  AND book_type_code=p_book_type
		  AND process_Flag+0=4
		  AND NVL(location,'X')=NVL(a.location,'X')
		  AND NVL(expense_account,'X')=NVL(a.expense_account,'X'));


CURSOR c_update_preview(p_request_id NUMBER,p_book_type VARCHAR2)
IS
SELECT a.asset_id,
       NVL(a.location,'X') location,
       NVL(a.expense_account,'X') expense_account
  FROM xx_fa_retire_stg a
 WHERE a.request_id=p_request_id
   AND a.process_flag=1
   AND a.process_mode='RUN'
   AND a.book_type_code=p_book_type
   AND EXISTS (SELECT 'x'
		 FROM xx_fa_retire_stg
		WHERE asset_id=a.asset_id
		  AND process_mode='PREVIEW'
		  AND book_type_code=p_book_type
		  AND process_Flag+0=4
		  AND NVL(location,'X')=NVL(a.location,'X')
		  AND NVL(expense_account,'X')=NVL(a.expense_account,'X'));


CURSOR c_nbv_rtd(p_request_id NUMBER,p_book VARCHAR2)
IS
SELECT asset_id,
       retirement_date,
       fa_current_cost,
       current_units,
       life_in_months,
       nbv,
       book_type_code,
       NVL(cost_of_removal,0) cost_of_removal,
       NVL(pos_to_be,0) pos_to_be,
       sum(units_retired) units_retired,
       sum(cost_to_be_retired) cost_retired
  FROM xx_fa_retire_stg
 WHERE request_id=p_request_id
   AND process_flag=1
   AND process_mode='PREVIEW'
   AND book_type_code=p_book
   AND error_flag='N'
 GROUP BY asset_id,
	  retirement_date,
	  fa_current_cost,
	  current_units,
          life_in_months,
	  nbv,
          book_type_code,
          NVL(cost_of_removal,0),
	  NVL(pos_to_be,0);


v_request_id		NUMBER:=fnd_global.conc_request_id;
v_fa_period     	VARCHAR2(25);
v_run_check		NUMBER:=0;

v_new_deprn		NUMBER;
v_mnt_to_adj		NUMBER;
v_catch_up_adjmnt  	NUMBER;
v_deprn_expense		NUMBER;
v_new_rlife		NUMBER;
v_new_adj_nbv		NUMBER;
ln_distribution_id	NUMBER;
ln_location_id		NUMBER;
ln_ccid			NUMBER;
v_gnls_amnt		NUMBER;
v_nbv_rtrd		NUMBER;
v_cost_retired		NUMBER;
v_loc_description	VARCHAR2(240);
v_prorate_pct		NUMBER;
v_deprn_amount		NUMBER;
v_deprn_factor		NUMBER;
v_rtd_pnum		NUMBER;
v_cur_pnum		NUMBER;
v_cal_open_date		DATE;
v_pos			NUMBER;
BEGIN

  OPEN c_get_context_date;
  FETCH c_get_context_date INTO G_trx_date,v_cal_open_date;
  CLOSE c_get_context_date;

  DELETE 
    FROM xx_fa_retire_stg
   WHERE process_flag=1
     AND asset_id is null;
  COMMIT;

  UPDATE xx_fa_retire_stg
     SET request_id=v_request_id,
	 error_flag='N',
	 -- retirement_date=retirement_date+1,   -- Defect 27379
	 proceeds_of_sale=pos_to_be,
         asset_cost_retired=cost_to_be_retired
   WHERE process_Flag=1
     AND book_type_code=p_book_type
     AND process_mode=p_process_mode;
  COMMIT;

  UPDATE xx_fa_retire_stg
     SET process_flag=7,
	 error_flag='Y',
	 error_message='Either Units Retired or Cost to be retired should be blank'
   WHERE process_flag=1
     AND book_type_code=p_book_type
     AND process_mode=p_process_mode
     AND units_retired IS NOT NULL
     AND cost_to_be_retired IS NOT NULL;
  COMMIT;

  purge_proc;

  check_duplicate_assets(p_book_type,p_process_mode,v_request_id);

  BEGIN
    SELECT period_name 
      INTO v_fa_period	
      FROM fa_calendar_periods
     WHERE TRUNC(G_trx_date) between start_date and end_date
       AND calendar_type='OD_ALL_MONTH';
  EXCEPTION
    WHEN others THEN
      v_fa_period:=NULL;
  END;


  FOR cur IN c_check_preview(v_request_id,p_book_type) LOOP

    UPDATE xx_fa_retire_stg
       SET process_flag=7
     WHERE asset_id=cur.asset_id
       AND process_Flag+0=4
       AND book_type_code=p_book_type
       AND process_mode='PREVIEW'
       AND NVL(location,'X')=NVL(cur.location,'X')
       AND NVL(expense_account,'X')=NVL(cur.expense_account,'X');

  END LOOP;
  COMMIT;

  IF p_process_mode='RUN' THEN

     FOR cur IN c_check_run(v_request_id,p_book_type) LOOP

       v_run_check:=v_run_check+1;
  
       fnd_file.put_line(fnd_file.LOG, 'PREVIEW was not completed for Assets : '||TO_CHAR(cur.asset_id));

     END LOOP;

     IF v_run_check>0 THEN
        UPDATE xx_fa_retire_stg
           SET process_flag=7
        WHERE request_id=v_request_id;
        COMMIT;

        x_errbuf:='PREVIEW was not completed for Assets specified in RUN mode';
        x_retcode:=2;
        RETURN;
     END IF;

     FOR cur IN c_update_preview(v_request_id,p_book_type) LOOP

        UPDATE xx_fa_retire_stg
           SET process_flag=7
        WHERE asset_id=cur.asset_id
          AND process_mode='PREVIEW'
          AND book_type_code=p_book_type
	  and NVL(location,'X')=NVL(cur.location,'X')
	  and NVL(expense_account,'X')=NVL(cur.expense_account,'X');
        COMMIT;

     END LOOP;
  
  END IF;

  FOR cur IN c_derive_id(v_request_id) LOOP

      ln_location_id 	:=0;
      ln_ccid	     	:=0;
      ln_distribution_id:=0;

      BEGIN

	SELECT location_id
	  INTO ln_location_id
	  FROM fa_locations_kfv
         WHERE concatenated_segments=LTRIM(RTRIM(cur.location));
        
      EXCEPTION

	WHEN others THEN
	  ln_location_id:=NULL;
	  fnd_file.put_line(fnd_file.LOG, 'Unable to derive location id for :'||cur.location);
      END;

      BEGIN

	SELECT code_combination_id
	  INTO ln_ccid
	  FROM gl_code_combinations_kfv
         WHERE concatenated_segments=LTRIM(RTRIM(cur.expense_account));
        
      EXCEPTION

	WHEN others THEN
	  ln_ccid:=NULL;
	  fnd_file.put_line(fnd_file.LOG, 'Unable to derive ccid for :'||cur.expense_account);
      END;

      UPDATE xx_fa_retire_stg
         SET location_id=ln_location_id,
	     expense_acct_id=ln_ccid
       WHERE rowid=cur.drowid;

      BEGIN

	SELECT distribution_id
	  INTO ln_distribution_id
	  FROM fa_distribution_history
         WHERE asset_id=cur.asset_id
           AND location_id=ln_location_id
	   AND code_combination_id=ln_ccid
	   AND date_ineffective IS NULL;

	UPDATE xx_fa_retire_stg
	   SET distribution_id=ln_distribution_id,
               retirement_process='DISTRIBUTION'
         WHERE rowid=cur.drowid;
      EXCEPTION

	WHEN others THEN
	  ln_distribution_id:=NULL;
	  fnd_file.put_line(fnd_file.LOG, 'Exception while deriving distribution id in c_derive_id');
	  fnd_file.put_line(fnd_file.LOG, 'Unable to derive distribution_id for :'||TO_CHAR(cur.asset_id));
	  UPDATE xx_fa_retire_stg
	     SET error_flag='Y',
	         error_message=error_message||','||'Unable to derive distribution id in c_derive_id cursor'
	   WHERE rowid=cur.drowid;
      END;

  END LOOP;
  COMMIT;

  FOR c IN C1_loc LOOP

    FOR cur IN c_asset_loc(c.asset_id,p_book_type,c.location_id) LOOP

	BEGIN
          SELECT description
	    INTO v_loc_description
	    FROM hr_locations_all
           WHERE SUBSTR(location_code,1,6)=cur.building;
        EXCEPTION
          WHEN others THEN
	    v_loc_description:=NULL;
	END;


	  UPDATE xx_fa_retire_stg
	     SET description=cur.description
		,company=cur.company
		,building=cur.building	
		,location_description=v_loc_description
		,costcenter=cur.costcenter
		,lob=cur.lob
		,major=cur.major
		,minor=cur.minor
		,subminor=cur.subminor
		,date_placed_in_service=cur.date_placed_in_service
		,life_in_months=cur.life_in_months
		,fa_retire_period=v_fa_period
		,deprn_method_code=cur.deprn_method_code
		,asset_prorate_con=cur.prorate_convention_code
		,fa_current_cost=cur.cost
		,current_units=cur.current_units
		,legacy_asset_id=cur.legacy_asset_id
		,tax_asset_id=cur.tax_asset_id
	   WHERE asset_id=cur.asset_id
             AND request_id+0=v_request_id
	     AND book_type_code=p_book_type
	     AND process_flag=1
	     AND process_mode=p_process_mode
	     AND NVL(location_id,-1)=NVL(c.location_id,-1);

	 IF SQL%NOTFOUND THEN
            fnd_file.put_line(fnd_file.LOG, 'Unable to update details for the asset :'||TO_CHAR(cur.asset_id));
	 END IF;

    END LOOP;
  END LOOP;  
  COMMIT;


  FOR c IN C1 LOOP

    FOR cur IN c_asset(c.asset_id,p_book_type) LOOP

	BEGIN
          SELECT description
	    INTO v_loc_description
	    FROM hr_locations_all
           WHERE SUBSTR(location_code,1,6)=cur.building;
        EXCEPTION
          WHEN others THEN
	    v_loc_description:=NULL;
	END;


	  UPDATE xx_fa_retire_stg
	     SET description=cur.description
		,company=cur.company
		,building=cur.building	
		,location_description=v_loc_description
		,costcenter=cur.costcenter
		,lob=cur.lob
		,major=cur.major
		,minor=cur.minor
		,subminor=cur.subminor
		,date_placed_in_service=cur.date_placed_in_service
		,life_in_months=cur.life_in_months
		,fa_retire_period=v_fa_period
		,deprn_method_code=cur.deprn_method_code
		,asset_prorate_con=cur.prorate_convention_code
		,fa_current_cost=cur.cost
		,current_units=cur.current_units
		,legacy_asset_id=cur.legacy_asset_id
		,tax_asset_id=cur.tax_asset_id
	   WHERE asset_id=cur.asset_id
             AND request_id+0=v_request_id
	     AND book_type_code=p_book_type
	     AND process_flag=1
	     AND process_mode=p_process_mode;

	 IF SQL%NOTFOUND THEN
            fnd_file.put_line(fnd_file.LOG, 'Unable to update details for the asset :'||TO_CHAR(cur.asset_id));
	 END IF;

    END LOOP;
  END LOOP;  
  COMMIT;

  UPDATE xx_fa_retire_stg
     SET error_flag='Y',error_message='Asset does not exists in the system',
	 process_flag=7
   WHERE process_Flag=1
     AND book_type_code=p_book_type
     AND process_mode=p_process_mode
     AND description IS NULL;
  COMMIT;

  UPDATE xx_fa_retire_stg
     SET retirement_process='DISTRIBUTION'
   WHERE process_Flag+0=1
     AND book_type_code=p_book_type
     AND process_mode=p_process_mode
     AND request_id=v_request_id
     AND location IS NULL
     AND expense_account IS NULL
     AND units_retired>0 
     AND units_retired<current_units;
  COMMIT;

  FOR cur IN c_derived_id_partial(v_request_id) LOOP

      ln_distribution_id:=0;

      BEGIN

	SELECT distribution_id
	  INTO ln_distribution_id
	  FROM fa_distribution_history
         WHERE asset_id=cur.asset_id
	   AND date_ineffective IS NULL;

	UPDATE xx_fa_retire_stg
	   SET distribution_id=ln_distribution_id
         WHERE rowid=cur.drowid;
        
      EXCEPTION

	WHEN others THEN
	  ln_distribution_id:=NULL;
	  fnd_file.put_line(fnd_file.LOG, 'Unable to derive distribution_id for :'||TO_CHAR(cur.asset_id));
	  UPDATE xx_fa_retire_stg
	     SET error_flag='Y',
	         error_message=error_message||','||'Unable to derive distribution id'
	   WHERE rowid=cur.drowid;
      END;

  END LOOP;
  COMMIT;

  IF p_process_mode='PREVIEW' THEN


     FOR cur IN c_nbv(v_request_id) LOOP
 
       derive_nbv(cur.asset_id,cur.fa_current_cost,cur.book_type_code,v_request_id);

     END LOOP;
     COMMIT;

     UPDATE xx_fa_retire_stg
        SET asset_cost_retired=round(((fa_current_cost/current_units)*units_retired),2)
      WHERE request_id+0=v_request_id
	AND process_flag=1
	AND process_mode='PREVIEW'
	AND book_type_code=p_book_type	
        AND error_flag='N'
	AND cost_to_be_retired IS NULL;
     COMMIT;

  END IF;

  IF p_process_mode='RUN' THEN

     FOR cur IN c_retire(v_request_id) LOOP

         xx_retire_nd ( cur.asset_id
  	  	       ,v_request_id
 		       ,cur.book_type_code
		       ,cur.retire_convention	
		       ,cur.retirement_date
		       ,cur.units_retired
		       ,cur.cost_to_be_retired
		       ,cur.pos_to_be
		       ,cur.retirement_type
		       ,cur.sold_to
		       ,cur.comments
		       ,cur.cost_of_removal
		      );

     END LOOP;

     xx_retire_partial(v_request_id,p_book_type,p_process_mode);

     submit_calculate_gain_loss(p_book_type);

     FOR cur IN c_retire_update(v_request_id) LOOP

         BEGIN

           v_gnls_amnt		:=NULL;
           v_nbv_rtrd		:=NULL;
	   v_cost_retired	:=NULL;
	   v_pos		:=NULL;

           SELECT gain_loss_amount,
	          nbv_retired,
	          cost_retired,
	          proceeds_of_sale
             INTO v_gnls_amnt,
     	          v_nbv_rtrd,
	          v_cost_retired,
		  v_pos
             FROM fa_retirements
            WHERE retirement_id=cur.retirement_id
              AND asset_id+0=cur.asset_id
              AND book_type_code=cur.book_type_code
  	      AND status='PROCESSED';

           UPDATE xx_fa_retire_stg
	      SET gain_loss_amount=v_gnls_amnt,
	          nbv_retired=v_nbv_rtrd,
	          asset_cost_retired=v_cost_retired,
		  proceeds_of_sale=v_pos
            WHERE asset_id=cur.asset_id
              AND request_id+0=v_request_id
              AND book_type_code=p_book_type
	      AND process_mode=p_process_mode;
    
           COMMIT;

         EXCEPTION
           WHEN others THEN
	     fnd_file.put_line(fnd_file.LOG, 'Unable to get retirement Information for the asset :' ||TO_CHAR(cur.asset_id)||
					 ', Retirement id :'||TO_CHAR(cur.retirement_id)); 
         END;

     END LOOP;

  END IF;  --IF p_process_mode='RUN' THEN

  submit_reports(v_request_id);

  Update xx_fa_retire_stg 
     set process_Flag=DECODE(p_process_mode,'PREVIEW',4,7)
   where request_id=v_request_id
     AND process_flag=1;
  COMMIT;	
 
EXCEPTION
  WHEN others THEN 
    x_errbuf:=SQLERRM;
    x_retcode:=2;      
END asset_retirement;

END XX_FA_MASS_RETIRE_PKG;
/
