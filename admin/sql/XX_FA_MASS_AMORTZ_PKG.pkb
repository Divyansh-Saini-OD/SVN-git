SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
set serveroutput on;
CREATE OR REPLACE PACKAGE BODY XX_FA_MASS_AMORTZ_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_FA_AMORTZ_PKG.pkb  	   	               |
-- | Description :  OD FA Mass Amortization Pkg                        |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       21-Nov-2012 Paddy Sanjeevi     Initial version           |
-- |1.1       19-DEC-2012 Paddy Sanjeevi     Modified remaining life   |
-- |                                         Defect 21908              |
-- |1.2	      05-Mar-2013 Paddy Sanjeevi     Modified for Tax Books    |
-- |2.0       28-Aug-2013 Jay Gupta          R12 - Retrofit            |
-- |2.1       03-Dec-2013 Paddy Sanjeevi     Modified QC Defect 26624  |
-- |2.5       21-Jan-2014 Paddy Sanjeevi     Defect 27379              |
-- |2.6       05-Nov-2015 Madhu Bolli    	 E3043 - R122 Retrofit Table Schema Removal(defect#36306)|
-- +===================================================================+
AS
 
-- +====================================================================+
-- | Name        :  get_asset_url                                       |
-- | Description :  This function is to get asset rem life              |
-- |                                                                    |
-- | Parameters  :  asset_id, book                                      |
-- +====================================================================+

FUNCTION get_asset_rl(p_asset_id IN NUMBER,p_book IN VARCHAR2)
RETURN NUMBER
IS

  l_rlife_years NUMBER:=0;
  l_rlife_months NUMBER:=0;
  l_rlife NUMBER:=0;

  dummy_num number;  dummy_char varchar2(10);  dummy_bool boolean;
  v_num_per_fiscal_year	number;
  v_num_per_fiscal_year_prorate       number;   -- Bug#6151598
  initial_pc			number;
  initial_cpod 		date;
  initial_cpcd			date;
  diff 			number;
  l_prorate_date		date;
  l_min_cpod			date;
  l_impairment_rsv             number; --Bug#7293626 
BEGIN
  select prorate_date
    into   l_prorate_date
    from   fa_books
   where book_type_code = p_book
     and   asset_id       = p_asset_id
     and   date_ineffective is null;

  select min(calendar_period_open_date)
    into l_min_cpod
    from fa_deprn_periods
   where book_type_code = p_book;

  select number_per_fiscal_year 
    into v_num_per_fiscal_year
    from fa_calendar_types where calendar_type=(select  			decode(fab.conversion_date,null,fabc.deprn_calendar,fabc.prorate_calendar) 
                                            from fa_book_controls fabc,fa_books fab 
                                            where fabc.book_type_code = p_book 
                                            and fab.asset_id = p_asset_id 
                                            and fab.book_type_code=fabc.book_type_code 
                                            and fab.transaction_header_id_out is null);
  select number_per_fiscal_year into v_num_per_fiscal_year
    from fa_calendar_types where calendar_type=(select fabc.prorate_calendar 
                                            from fa_book_controls fabc,fa_books fab 
                                            where fabc.book_type_code = p_book 
                                            and fab.asset_id = p_asset_id 
                                            and fab.book_type_code=fabc.book_type_code 
                                            and fab.transaction_header_id_out is null);
  if (v_num_per_fiscal_year=12) then
     If l_prorate_date <= l_min_cpod then
       if (v_num_per_fiscal_year_prorate=12) and (l_prorate_date < l_min_cpod ) then

       -- Bug fix 5971776 (Modified the following sql query to pick fiscal year from fa_fiscal_year 
       -- instead of directly using fcp1.end_date/fcp2.end_date/fcp3.end_date to avoid wrong 
       -- calculation of remaining life in case fiscal year doesnt start from January)
   
       select decode (fab.conversion_date,
                NULL, fab.life_in_months -
                      ((fafy1.fiscal_year*12 +fcp1.period_num) -
                       (fafy2.fiscal_year*12 + fcp2.period_num)),
                fab.life_in_months -
                ((fafy1.fiscal_year*12 +fcp1.period_num) -
                     (fafy3.fiscal_year*12 + fcp3.period_num))
              )
        into dummy_num
        From fa_books fab,
             fa_calendar_periods fcp1,  -- open
             fa_calendar_periods fcp2,  -- prorate
             fa_calendar_periods fcp3,  -- deprn_start
             fa_book_controls    fabc,
             fa_deprn_periods    fdp,
             fa_fiscal_year      fafy1,
             fa_fiscal_year      fafy2,
             fa_fiscal_year      fafy3
      where  fab.asset_id          = p_asset_id
        and fab.Book_type_code    = p_book
        and fab.transaction_header_id_out is null
        and fabc.book_type_code = fab.book_type_code
        and fdp.period_counter = (select max(dp.period_counter)
				from fa_deprn_periods dp
				where dp.book_type_code = p_book)
        and fdp.book_type_code = fab.book_type_code
        and fcp1.calendar_type= decode(fab.conversion_date,
                                     NULL,fabc.prorate_calendar,
                                     fabc.deprn_calendar)
        and fcp1.start_date=fdp.calendar_period_open_date
        and fcp2.calendar_type=fabc.prorate_calendar
        and fab.prorate_date between fcp2.start_date and fcp2.end_date
        and fcp3.calendar_type=fabc.deprn_calendar
        and fab.deprn_start_date between fcp3.start_date and fcp3.end_date
        and fabc.fiscal_year_name = fafy1.fiscal_year_name
        and fcp1.end_date between fafy1.start_date and fafy1.end_date
        and fabc.fiscal_year_name = fafy2.fiscal_year_name
        and fcp2.end_date between fafy2.start_date and fafy2.end_date
        and fabc.fiscal_year_name = fafy3.fiscal_year_name
        and fcp3.end_date between fafy3.start_date and fafy3.end_date;  

        -- Bug#6151598

       else    --       if (v_num_per_fiscal_year_prorate=12) and (l_prorate_date < l_min_cpod ) then
         select decode(
                fab.conversion_date,
                NULL,
                fab.life_in_months - floor(months_between(
                fdp.CALENDAR_PERIOD_CLOSE_DATE,
                fab.prorate_date)),
                fab.life_in_months - floor(months_between(
                fdp.CALENDAR_PERIOD_CLOSE_DATE,
                fab.deprn_start_date)))
          into  dummy_num
          from   fa_books fab, fa_deprn_periods fdp
         where  fab.book_type_code = p_book
           and    fdp.book_type_code = p_book
           and    fab.asset_id = p_asset_id
           and    fab.date_ineffective is null
           and    fdp.PERIOD_CLOSE_DATE is null;
       end if; -- v_num_per_fiscal_year_prorate=12   Bug#6151598
     else       -- If l_prorate_date <= l_min_cpod then
        select decode (fab.conversion_date, 
                NULL, fab.life_in_months - 
                      (fdp1.period_counter - 
                      fdp2.period_counter), 
                fab.life_in_months - 
                (fdp1.period_counter - 
                fdp3.period_counter)) 
          into dummy_num
          From fa_books fab, 
               fa_deprn_periods fdp1,  -- open 
               fa_deprn_periods fdp2,  -- prorate 
               fa_deprn_periods fdp3  -- deprn_start 
         where fab.asset_id          = p_asset_id
           and fab.Book_type_code    = p_book
           and fab.transaction_header_id_out is null
           and fab.book_type_code    = fdp1.book_type_code 
           and fdp1.period_counter = (select max(dp.period_counter)
				from fa_deprn_periods dp
				where dp.book_type_code = p_book)
           and fab.book_type_code    = fdp2.book_type_code 
           and (fab.prorate_date      between fdp2.calendar_period_open_date and 
                                    fdp2.calendar_period_close_date 
             or (fab.prorate_date>fdp2.calendar_period_close_date
                and fdp2.period_close_date is null)
                )
           and fab.book_type_code    = fdp3.book_type_code 
           and (fab.deprn_start_date  between fdp3.calendar_period_open_date and 
                                    fdp3.calendar_period_close_date
	       or (fab.deprn_start_date>fdp3.calendar_period_close_date
          and fdp3.period_close_date is null)); --Bug#6147597 (Added the or condition)
     end if; --l_prorate_date < l_min_cpod
  
  else   --if (v_num_per_fiscal_year=12) then

    -- Populate remaining_life_years and remaining_life_months
    -- BUG# 2108071: modified to handle new logic to use prorate
    -- date in deriving remaining life for non-short tax assets
    --     bridgway   11/13/01
    select decode(
             fab.conversion_date,
             NULL,
             fab.life_in_months - floor(months_between(
                fdp.CALENDAR_PERIOD_CLOSE_DATE,
                fab.prorate_date)),
             fab.life_in_months - floor(months_between(
                fdp.CALENDAR_PERIOD_CLOSE_DATE,
                fab.deprn_start_date)))
    into   dummy_num
    from   fa_books fab, fa_deprn_periods fdp
    where  fab.book_type_code = p_book
    and    fdp.book_type_code = p_book
    and    fab.asset_id = p_asset_id
    and    fab.date_ineffective is null
    and    fdp.PERIOD_CLOSE_DATE is null;
  end if;  -- v_num_per_fiscal_year=12
  if (dummy_num < 1) then
        l_rlife_years := 0;
        l_rlife_months := 0;
  else
        l_rlife_years := floor(dummy_num/12);
        l_rlife_months := mod(dummy_num,12);
  end if;

  l_rlife:=NVL(l_rlife_years,0)*12+NVL(l_rlife_months,0);
  RETURN(l_rlife);
exception
when others then
  fnd_file.put_line(fnd_file.LOG, 'Error in getting rlife for the asset :'||to_char(p_asset_id) ||','||SQLERRM);
  RETURN(l_rlife);
  
END get_asset_rl;


-- +====================================================================+
-- | Name        :  purge_proc                                          |
-- | Description :  This procedure is to purge the processed records    |
-- |                in the custom table xx_fa_amortz_stg                |
-- | Parameters  :                                                      |
-- +====================================================================+


PROCEDURE purge_proc
IS


CURSOR C1
IS
SELECT rowid drowid
  FROM xx_fa_amortz_stg
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
      FROM xx_fa_amortz_stg
     WHERE rowid=cur.drowid;

  END LOOP;
  COMMIT;
EXCEPTION
  WHEN others THEN
    fnd_file.put_line(fnd_file.LOG, 'Error in Purging Processed Records : '||SQLERRM);
END purge_proc;

-- +====================================================================+
-- | Name        :  submit_reports                                      |
-- | Description :  This procedure is to submit amortization and        |
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
	 	                template_code => 'XXFAAMTR', 
				template_language => 'en', 
				template_territory => 'US', 
			        output_format => 'EXCEL');

  IF (v_addlayout) THEN
     fnd_file.put_line(fnd_file.LOG, 'The layout has been submitted');
  ELSE
     fnd_file.put_line(fnd_file.LOG, 'The layout has not been submitted');
  END IF;


  ln_request_id1:=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXFAAMTR',
					   'OD: FA Mass Amortization Report',NULL,FALSE,
					    p_request_id
					  );
  IF ln_request_id1>0 THEN
     fnd_file.put_line(fnd_file.LOG, 'OD FA Mass Amortization Report Request id : '||TO_CHAR(ln_request_id1));
     COMMIT;
  END IF;


  v_addlayout:=FND_REQUEST.ADD_LAYOUT( template_appl_name => 'XXFIN',
	 	                template_code => 'XXFAAMTE', 
				template_language => 'en', 
				template_territory => 'US', 
			        output_format => 'EXCEL');

  IF (v_addlayout) THEN
     fnd_file.put_line(fnd_file.LOG, 'The layout has been submitted');
  ELSE
     fnd_file.put_line(fnd_file.LOG, 'The layout has not been submitted');
  END IF;


  ln_request_id2:=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXFAAMTE',
					   'OD: FA Mass Amortization Exception Report',NULL,FALSE,
					    p_request_id
					  );
  IF ln_request_id2>0 THEN
     fnd_file.put_line(fnd_file.LOG, 'Request id : '||TO_CHAR(ln_request_id2));
     COMMIT;
  END IF;

EXCEPTION
  WHEN others THEN
    fnd_file.put_line(fnd_file.LOG, 'When others in Submit_reports :'||sqlerrm);
END submit_reports;

-- +====================================================================+
-- | Name        :  derive_nbv                                          |
-- | Description :  This procedure to derive net book value             |
-- |                                                                    |
-- | Parameters  :  asset_id, cost,book,request_id                      |
-- +====================================================================+

PROCEDURE derive_nbv( p_asset_id 	IN  NUMBER
		     ,p_cost     	IN  NUMBER
		     ,p_book     	IN  VARCHAR2
		     ,p_request_id 	IN NUMBER
		     ,p_process_mode	IN VARCHAR2
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
  -- V2.0, Declare record type
  lrec_fa_log FA_API_TYPES.log_level_rec_type;

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

   v_nbv:=(p_cost - v_deprn_rsv - nvl(l_impairment_rsv,0));

/*
   IF p_process_mode='PREVIEW' THEN

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
     v_nbv := v_nbv + NVL(v_deprn_open_period,0);

   END IF;
*/

    UPDATE xx_fa_amortz_stg
       SET nbv=v_nbv,
	   deprn_reserve=v_deprn_rsv,
	   ytd_deprn=v_ytd_deprn
     WHERE asset_id=p_asset_id
       AND request_id+0=p_request_id
       AND book_type_code=p_book;  
EXCEPTION
  WHEN others THEN
    fnd_file.put_line(fnd_file.LOG, 'Error while deriving NBV for the asset :'||p_asset_id|| ','||SQLERRM);
END derive_nbv;

-- +====================================================================+
-- | Name        :  check_duplicate_assets                              |
-- | Description :  This procedure to delete the duplicate assets       |
-- |                for processing in the custom table                  |
-- | Parameters  :  asset_id, book                                      |
-- +====================================================================+

PROCEDURE check_duplicate_assets
IS

CURSOR c1 
IS
SELECT COUNT(1) cnt,
       asset_id,
       process_mode
  FROM xx_fa_amortz_stg
 WHERE process_flag=1
 GROUP BY asset_id,process_mode
 HAVING COUNT(1)>1;

 
CURSOR c2(p_asset_id NUMBER,p_mode VARCHAR2)
IS
SELECT asset_id,process_mode
  FROM xx_fa_amortz_stg
 WHERE process_flag=1
   AND asset_id=p_asset_id
   AND process_mode=p_mode;

   
  i number:=0;    

BEGIN

  FOR cur IN c1 LOOP
    i:=0;
    FOR c in c2(cur.asset_id,cur.process_mode) LOOP
        i:=i+1;
        IF i>1 THEN
        
          UPDATE xx_fa_amortz_stg
             SET process_flag=7
           WHERE process_flag+0=1
             AND asset_id=cur.asset_id
             AND process_mode=cur.process_mode
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
-- | Name        :  xx_asset_amortz_api                                 |
-- | Description :  This procedure is to do amortization by calling api |
-- |                                                                    |
-- | Parameters  :  asset_id, life, book, amort_adj, amort_date,        |
-- |                depreciation method, request_id                     |
-- +====================================================================+

PROCEDURE xx_asset_amortz_api(
			         p_asset_id 	IN NUMBER
			        ,p_life 	IN NUMBER
				,p_book		IN VARCHAR2
				,p_amort_adj	IN VARCHAR2
				,p_amort_sdate	IN DATE
				,p_deprn_method IN VARCHAR2
				,p_request_id 	IN NUMBER
			     )
IS

  l_trans_rec  			FA_API_TYPES.trans_rec_type; 
  l_asset_hdr_rec  		FA_API_TYPES.asset_hdr_rec_type;
  l_asset_fin_rec_adj  		FA_API_TYPES.asset_fin_rec_type;
  l_asset_fin_rec_new 		FA_API_TYPES.asset_fin_rec_type;
  l_asset_fin_mrc_tbl_new 	FA_API_TYPES.asset_fin_tbl_type;
  l_inv_trans_rec  		FA_API_TYPES.inv_trans_rec_type;
  l_inv_tbl 			FA_API_TYPES.inv_tbl_type;
  l_inv_rate_tbl 		FA_API_TYPES.inv_rate_tbl_type;
  l_asset_deprn_rec_adj 	FA_API_TYPES.asset_deprn_rec_type;
  l_asset_deprn_rec_new 	FA_API_TYPES.asset_deprn_rec_type;
  l_asset_deprn_mrc_tbl_new 	FA_API_TYPES.asset_deprn_tbl_type;
  l_inv_rec 			FA_API_TYPES.inv_rec_type;
  l_group_reclass_options_rec   FA_API_TYPES.group_reclass_options_rec_type;
  l_return_status 		VARCHAR2(1);
  l_mesg_count 			NUMBER:= 0;
  l_mesg_len 			NUMBER;
  l_mesg 			VARCHAR2(4000);
  l_msg				VARCHAR2(512);

BEGIN

   FND_PROFILE.PUT('PRINT_DEBUG', 'Y');
   FA_SRVR_MSG.Init_Server_Message;
   FA_DEBUG_PKG.Initialize;
  
   -- asset header info

   l_asset_hdr_rec.asset_id := p_asset_id;
   l_asset_hdr_rec.book_type_code := p_book;

   -- Transaction info

   IF p_amort_adj='YES' AND p_amort_sdate IS NOT NULL THEN

      l_trans_rec.amortization_start_date:=p_amort_sdate;
      l_trans_rec.transaction_date_entered:=p_amort_sdate;
      l_trans_rec.transaction_subtype:='AMORTIZED';

   END IF;

   -- Life change info

   l_asset_fin_rec_adj.life_in_months:=p_life;
   l_asset_fin_rec_adj.deprn_method_code:=p_deprn_method; 

   FA_ADJUSTMENT_PUB.do_adjustment
	(p_api_version 			=> 1.0,
	 p_init_msg_list 		=> FND_API.G_FALSE,
	 p_commit 			=> FND_API.G_FALSE,
	 p_validation_level 		=> FND_API.G_VALID_LEVEL_FULL,
	 x_return_status 		=> l_return_status,
	 x_msg_count 			=> l_mesg_count,
	 x_msg_data 			=> l_mesg,
	 p_calling_fn 			=> 'TEST_SCRIPT',
	 px_trans_rec 			=> l_trans_rec,
	 px_asset_hdr_rec 		=> l_asset_hdr_rec,
	 p_asset_fin_rec_adj 		=> l_asset_fin_rec_adj,
	 x_asset_fin_rec_new 		=> l_asset_fin_rec_new,
	 x_asset_fin_mrc_tbl_new 	=> l_asset_fin_mrc_tbl_new,
	 px_inv_trans_rec 		=> l_inv_trans_rec,
	 px_inv_tbl 			=> l_inv_tbl,
	 -- V2.0, not required in R12 px_inv_rate_tbl 		=> l_inv_rate_tbl,
	 p_asset_deprn_rec_adj 		=> l_asset_deprn_rec_adj,
	 x_asset_deprn_rec_new 		=> l_asset_deprn_rec_new,
	 x_asset_deprn_mrc_tbl_new 	=> l_asset_deprn_mrc_tbl_new,
	 p_group_reclass_options_rec => l_group_reclass_options_rec
	);

   IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN

      fa_debug_pkg.dump_debug_messages(max_mesgs=>0);
      l_mesg_count := fnd_msg_pub.count_msg;
  
      IF l_mesg_count > 0 THEN
	 l_msg := SUBSTR(fnd_msg_pub.get(fnd_msg_pub.G_FIRST,fnd_api.G_FALSE), 1, 512);
	 l_mesg:=l_msg;

	 FOR i IN 1..l_mesg_count - 1 LOOP
	     l_msg:=SUBSTR(fnd_msg_pub.get(fnd_msg_pub.G_NEXT, fnd_api.G_FALSE), 1, 512);
	     l_mesg:=l_mesg||','||l_msg;			
	 END LOOP;
 	 fnd_msg_pub.delete_msg();
      END IF;
      ROLLBACK;

      UPDATE xx_fa_amortz_stg
         SET error_flag='Y',
	     error_message=SUBSTR(l_mesg,1,4000)
       WHERE asset_id=p_asset_id
	 AND request_id+0=p_request_id
	 AND book_type_code=p_book;
      COMMIT;     
   ELSE
      COMMIT;
   END IF;
EXCEPTION
 WHEN others THEN
   FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error while Asset Adjustment :'||p_asset_id|| ','||SQLERRM);
END xx_asset_amortz_api;


-- +====================================================================+
-- | Name        :  derive_amortz                                       |
-- | Description :  This procedure is to derive amortization for asset  |
-- |                                                                    |
-- | Parameters  :  asset_id, book,request_id, process_mode             |
-- +====================================================================+

PROCEDURE derive_amortz( p_asset_id     IN NUMBER
                        ,p_book_type    IN VARCHAR2
			,p_request_id   IN NUMBER
			,p_process_mode IN VARCHAR2
		       )
IS

CURSOR get_amort_flag (c_book_type_code varchar2,
                       c_asset_id number)
IS 
SELECT 'Y' 
  FROM fa_books bk 
 WHERE bk.book_type_code= c_book_type_code 
   AND bk.asset_id= c_asset_id  
   AND (bk.rate_Adjustment_factor!=1 OR 
           (bk.rate_adjustment_factor = 1 and 
               exists 
                  (select 'YES'            -- and amortized before. 
                   from   fa_transaction_headers th, 
                          fa_methods mt 
                   where  th.book_type_code = bk.book_type_code 
                   and    th.asset_id =  bk.asset_id 
                   and    th.transaction_type_code = 'ADJUSTMENT' 
                   and    (th.transaction_subtype = 'AMORTIZED' 
                        OR th.transaction_key = 'UA')  
                   and    th.transaction_header_id = bk.transaction_header_id_in 
                   and    mt.method_code = bk.deprn_method_code 
                   and    mt.rate_source_rule IN ('TABLE','FLAT','PRODUCTION'))));


v_amortize_sdate	DATE;
l_trx_date           	DATE;
l_cal_per_close_date 	DATE;
l_amortized  	  	VARCHAR2(1);
l_amortize_adj   	VARCHAR2(3);
v_new_amrtz_date	DATE;
v_nlife			NUMBER;



BEGIN

  l_trx_date:=G_trx_date;
  l_cal_per_close_date:=G_cal_per_close_date;


  IF G_AMORTZ_FLAG='YES' THEN

     OPEN get_amort_flag(p_book_type,p_asset_id);
     FETCH get_amort_flag INTO l_amortized;
     CLOSE get_amort_flag;

     IF l_amortized = 'Y' THEN

        l_amortize_adj:='YES';

     ELSE

        l_amortize_adj:='NO';

     END IF;

  ELSE
    
     l_amortize_adj:='NO';

  END IF;

  IF p_process_mode='ALL' THEN
  
     IF l_amortize_adj='YES' THEN
   
        v_amortize_sdate:=l_trx_date;
 
     ELSE

        v_amortize_sdate:=NULL;

     END IF;

     UPDATE xx_fa_amortz_stg
        SET current_amrtz=l_amortize_adj,
	    current_amrtz_date=v_amortize_sdate
      WHERE asset_id=p_asset_id
        AND request_id+0=p_request_id
        AND book_type_code=p_book_type;

  ELSE

     BEGIN
       select amortization_start_date
 	 into v_new_amrtz_date
         from fa_transaction_headers a
        where a.asset_id=p_asset_id
          and a.book_type_code=p_book_type
          and a.transaction_type_code='ADJUSTMENT'
          and a.transaction_subtype='AMORTIZED'
          and a.transaction_header_id=(select max(transaction_header_id)
                                         from fa_transaction_headers
                                        where asset_id=a.asset_id
                                          and book_type_code=a.book_type_code
                                          and transaction_type_code='ADJUSTMENT'
                                          and transaction_subtype='AMORTIZED');
     EXCEPTION
       WHEN others THEN
         v_new_amrtz_date:=NULL;
     END;

    BEGIN
      SELECT life_in_months
	INTO v_nlife
        FROM fa_books_v
       WHERE asset_id=p_asset_id 
         AND book_type_code=p_book_type;
    EXCEPTION
      WHEN others THEN
        v_nlife:=NULL;
    END;

    UPDATE xx_fa_amortz_stg
       SET future_months=v_nlife,
	   future_amrtz=l_amortize_adj,
           future_amrtz_date=v_new_amrtz_date
     WHERE asset_id=p_asset_id
       AND request_id+0=p_request_id
       AND book_type_code=p_book_type;

  END IF;
  COMMIT;
EXCEPTION
  WHEN others THEN
    fnd_file.put_line(fnd_file.LOG, 'When others while deriving amortization for the asset : '||TO_CHAR(p_asset_id)||','||
				    SQLERRM);
END derive_amortz;


-- +====================================================================+
-- | Name        :  Asset_amortization                                  |
-- | Description :  This procedure is to process the assets for         |
-- |                amortization in the custom table xx_fa_amortz_stg   |
-- | Parameters  :  errbuf,retcode,process_mode,book_type               |
-- +====================================================================+

PROCEDURE asset_amortization ( x_errbuf      	OUT NOCOPY VARCHAR2
                              ,x_retcode     	OUT NOCOPY VARCHAR2
                 	      ,p_process_mode 	IN  VARCHAR2
			      ,p_book_type	IN  VARCHAR2	
  		             )
IS

CURSOR C1 
IS
SELECT asset_id
  FROM xx_fa_amortz_stg
 WHERE process_flag=1
   AND process_mode=p_process_mode
   AND book_type_code=p_book_type;

CURSOR c_asset(p_asset_id NUMBER)
IS
SELECT a.asset_id,    
       a.asset_number,                            
       a.description,  
       fb.book_type_code,                              
       fb.date_placed_in_service,                                
       FLOOR(months_between(G_trx_date,fb.date_placed_in_service)) months_in_service,
       FLOOR((G_trx_date-fb.date_placed_in_service)) days_in_service,
       fb.life_in_months,    
       fb.cost,                                
       fb.deprn_method_code,
       ds.deprn_amount,    
       ds.ytd_deprn,                                
       ds.deprn_reserve,                                
       fb.recoverable_cost,
       fcat.segment1 Major,                                
       fcat.segment2 Minor,                                
       fcat.segment3 Subminor                            
  FROM fa_categories_b fcat,
       FA_DEPRN_SUMMARY ds,                                   
       fa_books_v fb,    
       fa_additions a                                
 WHERE a.asset_id=p_asset_id
   AND fb.asset_id=a.asset_id
   AND fb.book_type_code=p_book_type
   AND ds.asset_id=fb.asset_id                                
   AND ds.book_type_code=fb.book_type_code                        
   AND DS.PERIOD_COUNTER = (SELECT max(DS1.PERIOD_COUNTER)                
                              FROM FA_DEPRN_SUMMARY DS1                
                             WHERE DS1.ASSET_ID=DS.ASSET_ID                
                               AND DS1.BOOK_TYPE_CODE = DS.BOOK_TYPE_CODE)
   AND fcat.category_id=a.asset_category_id 
   AND fcat.segment1 IN (SELECT flex_value
               FROM fnd_flex_values b,
                    Fnd_flex_value_sets a
              WHERE flex_value_set_name='XX_FA_REVAL_CATEGORY'
                AND b.flex_value_Set_id=a.flex_value_set_id
                AND b.enabled_flag='Y');


CURSOR c_get_cbcl(p_asset_id NUMBER)
IS
SELECT cc.segment1 company,                                
       cc.segment4 building,                                
       cc.segment2 costcenter,    
       cc.segment6 lob
  FROM gl_code_combinations cc,
       fa_distribution_history b    
 WHERE b.asset_id=p_asset_id
   AND b.date_ineffective is null                          
   AND b.book_type_code='OD US CORP'
   AND cc.code_combination_id=b.code_combination_id;

CURSOR c_nbv(p_request_id NUMBER)
IS
SELECT *
  FROM xx_fa_amortz_stg
 WHERE process_flag=1
   AND request_id=p_request_id
   AND process_mode=p_process_mode
   AND error_flag='N'
   AND book_type_code=p_book_type;


CURSOR c_check_preview(p_request_id NUMBER,p_book_type VARCHAR2)
IS
SELECT a.asset_id
  FROM xx_fa_amortz_stg a
 WHERE a.request_id=p_request_id
   AND a.process_mode='PREVIEW'
   AND a.process_flag=1
   AND a.book_type_code=p_book_type
   AND EXISTS (SELECT 'x'
		 FROM xx_fa_amortz_stg
		WHERE asset_id=a.asset_id
		  AND process_mode=a.process_mode
		  AND book_type_code=p_book_type
		  AND process_Flag+0=4);

CURSOR c_check_run(p_request_id NUMBER,p_book_type VARCHAR2)
IS
SELECT a.asset_id
  FROM xx_fa_amortz_stg a
 WHERE a.request_id=p_request_id
   AND a.process_flag=1
   AND a.process_mode='RUN'
   AND a.book_type_code=p_book_type
   AND NOT EXISTS (SELECT 'x'
		 FROM xx_fa_amortz_stg
		WHERE asset_id=a.asset_id
		  AND process_mode='PREVIEW'
		  AND book_type_code=p_book_type
		  AND process_Flag+0=4);


CURSOR c_update_preview(p_request_id NUMBER,p_book_type VARCHAR2)
IS
SELECT a.asset_id
  FROM xx_fa_amortz_stg a
 WHERE a.request_id=p_request_id
   AND a.process_flag=1
   AND a.process_mode='RUN'
   AND a.book_type_code=p_book_type
   AND EXISTS (SELECT 'x'
		 FROM xx_fa_amortz_stg
		WHERE asset_id=a.asset_id
		  AND process_mode='PREVIEW'
		  AND book_type_code=p_book_type
		  AND process_Flag+0=4);

CURSOR c_get_context_date
IS
SELECT greatest(calendar_period_open_date,
       least(sysdate, calendar_period_close_date)),
       calendar_period_close_date
  FROM fa_deprn_periods
 WHERE book_type_code = p_book_type
   AND period_close_date IS NULL;


v_request_id		NUMBER:=fnd_global.conc_request_id;
v_fa_period     	VARCHAR2(25);
v_run_check		NUMBER:=0;

v_new_deprn		NUMBER;
v_mnt_to_adj		NUMBER;
v_catch_up_adjmnt  	NUMBER;
v_deprn_expense		NUMBER;
v_new_rlife		NUMBER;
v_new_adj_nbv		NUMBER;
v_rlife			NUMBER:=0;
v_company		VARCHAR2(25);
v_building		VARCHAR2(25);
v_costcenter		VARCHAR2(25);
v_lob			VARCHAR2(25);
BEGIN

  DELETE 
    FROM xx_fa_amortz_stg
   WHERE process_flag=1
     AND (asset_id IS NULL OR process_mode IS NULL);
  COMMIT;

  purge_proc;

  check_duplicate_assets;

  UPDATE xx_fa_amortz_stg
     SET request_id=v_request_id,
	 --amrtz_date_to_process=amrtz_date_to_process+1,  -- Defect 27379
	 book_type_code=p_book_type,
	 error_flag='N'
   WHERE process_Flag=1
     AND process_mode=p_process_mode;
  COMMIT;

  BEGIN
    SELECT amortize_flag
      INTO G_AMORTZ_FLAG
      FROM fa_book_controls
     WHERE book_type_code = p_book_type;
  EXCEPTION
    WHEN others THEN
      G_AMORTZ_FLAG:=NULL;
  END;

  OPEN c_get_context_date;
  FETCH c_get_context_date INTO G_trx_date, G_cal_per_close_date;
  CLOSE c_get_context_date;

  FOR cur IN c_check_preview(v_request_id,p_book_type) LOOP

    UPDATE xx_fa_amortz_stg
       SET process_flag=7
     WHERE asset_id=cur.asset_id
       AND process_Flag+0=4
       AND book_type_code=p_book_type;

  END LOOP;
  COMMIT;

  IF p_process_mode='RUN' THEN

     FOR cur IN c_check_run(v_request_id,p_book_type) LOOP

       v_run_check:=v_run_check+1;
  
       fnd_file.put_line(fnd_file.LOG, 'PREVIEW was not completed for Assets : '||TO_CHAR(cur.asset_id));

     END LOOP;

     IF v_run_check>0 THEN
        UPDATE xx_fa_amortz_stg
           SET process_flag=7
        WHERE request_id=v_request_id;
        COMMIT;

        x_errbuf:='PREVIEW was not completed for Assets specified in RUN mode';
        x_retcode:=2;
        RETURN;
     END IF;

     FOR cur IN c_update_preview(v_request_id,p_book_type) LOOP

        UPDATE xx_fa_amortz_stg
           SET process_flag=7
        WHERE asset_id=cur.asset_id
          AND process_mode='PREVIEW'
          AND book_type_code=p_book_type;
        COMMIT;

     END LOOP;
  
  END IF;

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

  FOR c IN C1 LOOP

    FOR cur IN c_asset(c.asset_id) LOOP

	v_rlife:=0;
	v_rlife:=get_asset_rl(c.asset_id,cur.book_type_code);

	v_company		:=NULL;
	v_building		:=NULL;
	v_costcenter		:=NULL;
	v_lob			:=NULL;

	FOR cc IN c_get_cbcl(c.asset_id) LOOP

	  v_company		:=cc.company;
	  v_building		:=cc.building;
	  v_costcenter		:=cc.costcenter;
	  v_lob			:=cc.lob;

	END LOOP;

	  UPDATE xx_fa_amortz_stg
	     SET description=cur.description
		,book_type_code=cur.book_type_code
		,company=v_company
		,building=v_building	
		,costcenter=v_costcenter
		,lob=v_lob
		,major=cur.major
		,minor=cur.minor
		,subminor=cur.subminor
		,date_placed_in_service=cur.date_placed_in_service
		,asset_service_days=cur.days_in_service
		,asset_service_months=cur.months_in_service
		,life_in_months=cur.life_in_months
		,rem_life_months=v_rlife
		,fa_period=v_fa_period
		,deprn_amount=cur.deprn_amount
		,deprn_method_code=cur.deprn_method_code
		,cost=cur.cost
		,current_months=cur.life_in_months
	   WHERE asset_id=cur.asset_id
             AND request_id+0=v_request_id
	     AND book_type_code=p_book_type;

	 IF SQL%NOTFOUND THEN
            fnd_file.put_line(fnd_file.LOG, 'Unable to update details for the asset :'||TO_CHAR(cur.asset_id));
	 END IF;

    END LOOP;
  END LOOP;  
  COMMIT;

  UPDATE xx_fa_amortz_stg
     SET error_Flag='Y',
	 error_message='Unable to derive asset information'
   WHERE process_Flag=1
     AND process_mode=p_process_mode
     AND description IS NULL;
  COMMIT;


  FOR cur IN c_nbv(v_request_id) LOOP

    derive_amortz(cur.asset_id,cur.book_type_code,v_request_id,'ALL');

    derive_nbv(cur.asset_id,cur.cost,cur.book_type_code,v_request_id,p_process_mode);
       
  END LOOP;


  IF p_process_mode='RUN' THEN

     FOR cur IN c_nbv(v_request_id) LOOP

	IF (    ( cur.current_amrtz='NO' AND cur.amrtz_to_process='YES')
	     OR ( cur.current_amrtz='YES' AND cur.amrtz_to_process='YES')
	   ) THEN

             xx_asset_amortz_api( cur.asset_id
	  	  	         ,cur.life_to_process
                                 ,cur.book_type_code
			         ,cur.amrtz_to_process
			         ,cur.amrtz_date_to_process
			         ,cur.deprn_method_code
			         ,v_request_id
			        );
	END IF;


	IF (    ( cur.current_amrtz='NO' AND cur.amrtz_to_process='NO')
	     OR ( cur.current_amrtz='YES' AND cur.amrtz_to_process='NO')
	   ) THEN

             xx_asset_amortz_api( cur.asset_id
	  	  	         ,cur.life_to_process
                                 ,cur.book_type_code
			         ,'X'
			         ,NULL
			         ,cur.deprn_method_code
			         ,v_request_id
			        );
	END IF;

        derive_amortz(cur.asset_id,cur.book_type_code,v_request_id,p_process_mode);

    END LOOP;

  END IF;

  FOR cur IN c_nbv(v_request_id) LOOP

	v_new_deprn		:=0;
	v_mnt_to_adj		:=0;
	v_catch_up_adjmnt  	:=0;
	v_deprn_expense		:=0;
	v_new_rlife		:=0;
	v_new_adj_nbv		:=0;

       v_mnt_to_adj:=FLOOR(months_between(g_trx_date,cur.amrtz_date_to_process)); 

       IF (v_mnt_to_adj<0 OR v_mnt_to_adj IS NULL) THEN
	  v_mnt_to_adj:=0;
       END IF;

       v_new_adj_nbv:=cur.nbv+(cur.deprn_amount*v_mnt_to_adj);	

       v_new_rlife:=(cur.rem_life_months-(cur.current_months-cur.life_to_process)+v_mnt_to_adj);

       BEGIN
	 v_new_deprn:=v_new_adj_nbv/v_new_rlife;
       EXCEPTION
	 WHEN others THEN
	   v_new_deprn:=NULL;
       END;

       v_catch_up_adjmnt:=(v_new_deprn-cur.deprn_amount)*v_mnt_to_adj;

       v_deprn_expense:=v_new_deprn+v_catch_up_adjmnt;

       UPDATE xx_fa_amortz_stg
	  SET new_adj_nbv=v_new_adj_nbv,
	      new_rem_life=v_new_rlife,
	      new_deprn=v_new_deprn,
	      months_to_adjust=v_mnt_to_adj,
	      catch_up_adjmnt=v_catch_up_adjmnt,
	      deprn_expense=v_deprn_expense      
	WHERE asset_id=cur.asset_id
	  AND request_id+0=v_request_id
	  AND book_type_code=p_book_type;

  END LOOP;
  COMMIT;

  submit_reports(v_request_id);

  Update xx_fa_amortz_stg 
     set process_Flag=DECODE(p_process_mode,'PREVIEW',4,7)
   where request_id=v_request_id;
  COMMIT;	
 
EXCEPTION
  WHEN others THEN 
    x_errbuf:=SQLERRM;
    x_retcode:=2;      
END asset_amortization;

END XX_FA_MASS_AMORTZ_PKG;
/
