SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
set serveroutput on;
CREATE OR REPLACE PACKAGE BODY XX_FA_MASS_REVAL_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_FA_MASS_REVAL_PKG.pkb  	   	               |
-- | Description :  OD FA Mass Revaluation Pkg                         |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       03-Oct-2012 Paddy Sanjeevi     Initial version           |
-- |1.1       05-Nov-2012 Paddy Sanjeevi     Modify the calc of impcost|
-- |2.0       28-Aug-2013 Jay Gupta          R12 - Retrofit            |
-- |2.1       25-Nov-2013 Deepak V           Changes made to NBV calc. |
-- |                                         in preview mode.          |
-- |                                         QC Defect - 26624.        |
-- |2.2       03-Dec-2013 Paddy Sanjeevi     Modified QC Defect 26624  |
-- |2.3       24-Feb-2014 Paddy Sanjeevi     Defect 28153              |
-- |2.4       05-Mar-2014 Veronica Mairembam E3043: Modified for Defect|
-- |                                         28153                     |
-- |2.5       19-Feb-2015 Paddy Sanjeevi     Modified for Reval by asset|
-- |2.6       05-Nov-2015 Madhu Bolli    	 E3043 - R122 Retrofit Table Schema Removal(defect#36306)|
-- |2.7       13-Apr-2017 Rohit Gupta        Modified for defect #41506|
-- +===================================================================+
AS

FUNCTION BeforeReportTrigger 
return boolean 
IS
BEGIN
  IF p_report_type='EXCLUDED' THEN

     p_asset_where:=' AND cost=0 AND nbv=0 ';


  ELSIF p_report_type='NBVNONZERO' THEN

    -- p_asset_where:=' AND ( ( cost<>0 AND nbv<>0 ) OR  ( cost<>0 AND nbv=0 ) ) ';
	
	p_asset_where:=' AND  cost<>0 AND nbv<>0 ';     --Commented/Added for Defect 28153

  ELSIF p_report_type='NBVZERO' THEN

     p_asset_where:=' AND cost<>0 AND nbv=0 ';


  ELSIF p_report_type='RUN' THEN

     p_asset_where:=' AND error_flag = ''N'' AND (  (nbv<>0) OR (cost<>0 and NBV=0) )';

  ELSE

     p_asset_where:=' AND  1=1 ';

  END IF;
 
  RETURN(TRUE);    
END BeforeReportTrigger;

PROCEDURE purge_proc
IS

CURSOR C1
IS
SELECT rowid drowid
  FROM xx_fa_reval_loc_stg
 WHERE process_Flag=7
   AND creation_date<SYSDATE-30;

CURSOR C2
IS
SELECT rowid drowid
  FROM xx_fa_reval_assets_stg
 WHERE process_Flag=7
   AND creation_date<SYSDATE-30;

CURSOR C3
IS
SELECT rowid drowid
  FROM xx_fa_rvl_by_asset
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
      FROM xx_fa_reval_loc_stg
     WHERE rowid=cur.drowid;

  END LOOP;
  COMMIT;
 
  FOR cur IN C2 LOOP

    i:=i+1;
    IF i>=5000 THEN
       COMMIT;
       i:=i+1;
    END IF;
   
    DELETE
      FROM xx_fa_reval_assets_stg
     WHERE rowid=cur.drowid;

  END LOOP;
  COMMIT;

  FOR cur IN C3 LOOP

    i:=i+1;
    IF i>=5000 THEN
       COMMIT;
       i:=i+1;
    END IF;
   
    DELETE
      FROM xx_fa_rvl_by_asset
     WHERE rowid=cur.drowid;

  END LOOP;
  COMMIT;
EXCEPTION
  WHEN others THEN
    fnd_file.put_line(fnd_file.LOG, 'Error in Purging Processed Records : '||SQLERRM);
END purge_proc;


PROCEDURE submit_preview_reports(p_request_id NUMBER)
IS

  v_addlayout 		boolean;
  lc_boolean            BOOLEAN;
  lc_boolean1           BOOLEAN;
  ln_request_id1	NUMBER;
  ln_request_id2	NUMBER;
  ln_request_id3	NUMBER;
  ln_request_id4	NUMBER;



  v_phase		varchar2(100)   ;
  v_status		varchar2(100)   ;
  v_dphase		varchar2(100)	;
  v_dstatus		varchar2(100)	;
  x_dummy		varchar2(2000) 	;

BEGIN

  v_addlayout:=FND_REQUEST.ADD_LAYOUT( template_appl_name => 'XXFIN',
	 	                template_code => 'XXFAMARR', 
				template_language => 'en', 
				template_territory => 'US', 
			        output_format => 'EXCEL');

  IF (v_addlayout) THEN
     fnd_file.put_line(fnd_file.LOG, 'The layout has been submitted');
  ELSE
     fnd_file.put_line(fnd_file.LOG, 'The layout has not been submitted');
  END IF;


  ln_request_id1:=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXFAMARR',
					   'OD: FA Mass Revaluation Report',NULL,FALSE,
					    p_request_id,'EXCLUDED'
					  );
  IF ln_request_id1>0 THEN
     fnd_file.put_line(fnd_file.LOG, 'Request id : '||TO_CHAR(ln_request_id1));
     COMMIT;
  END IF;

  IF (FND_CONCURRENT.WAIT_FOR_REQUEST(ln_request_id1,1,60000,v_phase,
 			v_status,v_dphase,v_dstatus,x_dummy))  THEN

     IF v_dphase = 'COMPLETE' THEN

        fnd_file.put_line(fnd_file.LOG, 'Completed OD FA Mass Revalution Report for Excluded Assets');
	
     END IF;   

  END IF;   


  v_addlayout:=FND_REQUEST.ADD_LAYOUT( template_appl_name => 'XXFIN',
	 	                template_code => 'XXFAMARR', 
				template_language => 'en', 
				template_territory => 'US', 
			        output_format => 'EXCEL');

  IF (v_addlayout) THEN
     fnd_file.put_line(fnd_file.LOG, 'The layout has been submitted');
  ELSE
     fnd_file.put_line(fnd_file.LOG, 'The layout has not been submitted');
  END IF;


  ln_request_id3:=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXFAMARR',
					   'OD: FA Mass Revaluation Report',NULL,FALSE,
					    p_request_id,'NBVZERO'
					  );
  IF ln_request_id3>0 THEN
     fnd_file.put_line(fnd_file.LOG, 'Request id : '||TO_CHAR(ln_request_id3));
     COMMIT;
  END IF;

  IF (FND_CONCURRENT.WAIT_FOR_REQUEST(ln_request_id3,1,60000,v_phase,
 			v_status,v_dphase,v_dstatus,x_dummy))  THEN

     IF v_dphase = 'COMPLETE' THEN

        fnd_file.put_line(fnd_file.LOG, 'Completed OD FA Mass Revalution Report for Assets with cost<>0 and NBV=0');
	
     END IF;  

  END IF;   

  v_addlayout:=FND_REQUEST.ADD_LAYOUT( template_appl_name => 'XXFIN',
	 	                template_code => 'XXFAMARR', 
				template_language => 'en', 
				template_territory => 'US', 
			        output_format => 'EXCEL');

  IF (v_addlayout) THEN
     fnd_file.put_line(fnd_file.LOG, 'The layout has been submitted');
  ELSE
     fnd_file.put_line(fnd_file.LOG, 'The layout has not been submitted');
  END IF;


  ln_request_id2:=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXFAMARR',
					   'OD: FA Mass Revaluation Report',NULL,FALSE,
					    p_request_id,'NBVNONZERO'
					  );
  IF ln_request_id2>0 THEN
     fnd_file.put_line(fnd_file.LOG, 'Request id : '||TO_CHAR(ln_request_id2));
     COMMIT;
  END IF;

  IF (FND_CONCURRENT.WAIT_FOR_REQUEST(ln_request_id2,1,60000,v_phase,
 			v_status,v_dphase,v_dstatus,x_dummy))  THEN

     IF v_dphase = 'COMPLETE' THEN

        fnd_file.put_line(fnd_file.LOG, 'Completed OD FA Mass Revalution Report for Assets with NBV<>0');
	
     END IF;  

  END IF;   

  v_addlayout:=FND_REQUEST.ADD_LAYOUT( template_appl_name => 'XXFIN',
	 	                template_code => 'XXFAMAER', 
				template_language => 'en', 
				template_territory => 'US', 
			        output_format => 'EXCEL');

  IF (v_addlayout) THEN
     fnd_file.put_line(fnd_file.LOG, 'The layout has been submitted');
  ELSE
     fnd_file.put_line(fnd_file.LOG, 'The layout has not been submitted');
  END IF;


  ln_request_id4:=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXFAMAER',
					   'OD: FA Mass Revaluation Exception Report',NULL,FALSE,
					    p_request_id
					  );
  IF ln_request_id4>0 THEN
     fnd_file.put_line(fnd_file.LOG, 'Request id : '||TO_CHAR(ln_request_id4));
     COMMIT;
  END IF;

  IF (FND_CONCURRENT.WAIT_FOR_REQUEST(ln_request_id4,1,60000,v_phase,
 			v_status,v_dphase,v_dstatus,x_dummy))  THEN

     IF v_dphase = 'COMPLETE' THEN

        fnd_file.put_line(fnd_file.LOG, 'Completed OD FA Mass Revalution Exception Report');
	
     END IF;  

  END IF;  

EXCEPTION
  WHEN others THEN
    fnd_file.put_line(fnd_file.LOG, 'When others in Submit_review_reports :'||sqlerrm);
END submit_preview_reports;


PROCEDURE submit_run_reports(p_request_id NUMBER)
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
	 	                template_code => 'XXFAMARR', 
				template_language => 'en', 
				template_territory => 'US', 
			        output_format => 'EXCEL');

  IF (v_addlayout) THEN
     fnd_file.put_line(fnd_file.LOG, 'The layout has been submitted');
  ELSE
     fnd_file.put_line(fnd_file.LOG, 'The layout has not been submitted');
  END IF;


  ln_request_id1:=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXFAMARR',
					   'OD: FA Mass Revaluation Report',NULL,FALSE,
					    p_request_id,'RUN'
					  );
  IF ln_request_id1>0 THEN
     fnd_file.put_line(fnd_file.LOG, 'Request id : '||TO_CHAR(ln_request_id1));
     COMMIT;
  END IF;

  IF (FND_CONCURRENT.WAIT_FOR_REQUEST(ln_request_id1,1,60000,v_phase,
 			v_status,v_dphase,v_dstatus,x_dummy))  THEN

     IF v_dphase = 'COMPLETE' THEN

        fnd_file.put_line(fnd_file.LOG, 'Completed OD FA Mass Revalution Report');
	
     END IF;   

  END IF;   


  v_addlayout:=FND_REQUEST.ADD_LAYOUT( template_appl_name => 'XXFIN',
	 	                template_code => 'XXFAMAER', 
				template_language => 'en', 
				template_territory => 'US', 
			        output_format => 'EXCEL');

  IF (v_addlayout) THEN
     fnd_file.put_line(fnd_file.LOG, 'The layout has been submitted');
  ELSE
     fnd_file.put_line(fnd_file.LOG, 'The layout has not been submitted');
  END IF;


  ln_request_id2:=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXFAMAER',
					   'OD: FA Mass Revaluation Exception Report',NULL,FALSE,
					    p_request_id
					  );
  IF ln_request_id2>0 THEN
     fnd_file.put_line(fnd_file.LOG, 'Request id : '||TO_CHAR(ln_request_id2));
     COMMIT;
  END IF;

  IF (FND_CONCURRENT.WAIT_FOR_REQUEST(ln_request_id2,1,60000,v_phase,
 			v_status,v_dphase,v_dstatus,x_dummy))  THEN

     IF v_dphase = 'COMPLETE' THEN

        fnd_file.put_line(fnd_file.LOG, 'Completed OD FA Mass Revalution Exception Report');
	
     END IF;  

  END IF;   


END submit_run_reports;



FUNCTION get_nbv( p_asset_id IN  NUMBER
		 ,p_cost     IN  NUMBER
		 ,p_book     IN  VARCHAR2
		)
RETURN NUMBER
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
   RETURN(v_nbv);
EXCEPTION
  WHEN others THEN
    fnd_file.put_line(fnd_file.LOG, 'Error while deriving NBV for the asset :'||p_asset_id|| ','||SQLERRM);
    v_nbv:=NULL;
    RETURN v_nbv;
END get_nbv;


PROCEDURE xx_asset_reval_api( p_asset_id 	IN NUMBER
 			     ,p_reval_pct 	IN NUMBER
			     ,p_book		IN VARCHAR2
			     ,p_process_mode 	IN VARCHAR2
			     ,p_request_id	IN NUMBER)
IS

    l_trans_rec             FA_API_TYPES.trans_rec_type;
    l_asset_hdr_rec         FA_API_TYPES.asset_hdr_rec_type;
    l_reval_options_rec     FA_API_TYPES.reval_options_rec_type;

    l_return_status         VARCHAR2(1);
    l_mesg_count            number := 0;
    l_mesg_len              number;
    l_mesg                  varchar2(4000);
    v_new_cost		    NUMBER;

BEGIN

   FA_SRVR_MSG.Init_Server_Message;
   FA_DEBUG_PKG.Initialize;

   -- asset header info

   l_asset_hdr_rec.asset_id       := p_asset_id;
   l_asset_hdr_rec.book_type_code := p_book;
   l_trans_rec.transaction_date_entered := sysdate;

   -- reval info

   l_reval_options_rec.reval_percent := p_reval_pct; 

   IF p_process_mode='PREVIEW' THEN

     l_reval_options_rec.run_mode      := 'PREVIEW';

   ELSIF p_process_mode='RUN' THEN

     l_reval_options_rec.run_mode      := 'RUN';

   END IF;

   -- fully reserved assets

   IF p_reval_pct=-100 THEN

     l_reval_options_rec.reval_fully_rsvd_flag       := 'Y';
	 l_reval_options_rec.life_extension_factor       := 1;				--Added for defect #41506

   ELSE

     l_reval_options_rec.reval_fully_rsvd_flag       := NULL;

   END IF;

   FA_REVALUATION_PUB.do_reval
      (p_api_version             => 1.0,
       p_init_msg_list           => FND_API.G_FALSE,
       p_commit                  => FND_API.G_FALSE,
       p_validation_level        => FND_API.G_VALID_LEVEL_FULL,
       x_return_status           => l_return_status,
       x_msg_count               => l_mesg_count,
       x_msg_data                => l_mesg,
       p_calling_fn              => null,
       px_trans_rec              => l_trans_rec,
       px_asset_hdr_rec          => l_asset_hdr_rec,
       p_reval_options_rec       => l_reval_options_rec
      );

   IF  (fa_cache_pkg.fa_print_debug) then
       fa_debug_pkg.dump_debug_messages(max_mesgs => 0);
   END IF;

   l_mesg_count := fnd_msg_pub.count_msg;

   if l_mesg_count > 0 then

      l_mesg := chr(10) || substr(fnd_msg_pub.get
                                    (fnd_msg_pub.G_FIRST, fnd_api.G_FALSE),
                                     1, 512);
      for i in 1..(l_mesg_count - 1) loop
         l_mesg :=
                     substr(fnd_msg_pub.get
                            (fnd_msg_pub.G_NEXT,
                             fnd_api.G_FALSE), 1, 512);

      end loop;

      fnd_msg_pub.delete_msg();

   end if;

   IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN

      UPDATE xx_fa_reval_assets_stg
	 SET error_message=l_mesg,
	     error_flag='Y'
       WHERE asset_id=p_asset_id
         AND request_id=p_request_id;

   ELSE
	
      IF p_process_mode='PREVIEW' THEN

	 BEGIN
	 select new_cost
	   INTO v_new_cost
           from FA_MASS_REVAL_REP_ITF a
          where asset_id=p_asset_id
	    and creation_date=(select max(creation_date)
         		         from FA_MASS_REVAL_REP_ITF
			        where asset_id=a.asset_id);

	 UPDATE xx_fa_reval_assets_stg
	    SET new_cost=v_new_cost
	  WHERE asset_id=p_asset_id
            AND request_id=p_request_id;

	 EXCEPTION
	   WHEN others THEN
	     v_new_cost:=NULL;
	 END;

      END IF;

   END IF;

EXCEPTION
 WHEN others THEN
   fnd_file.put_line(fnd_file.LOG, 'While processing Revaluation for the asset :'||p_asset_id||','||SQLERRM);
END xx_asset_reval_api;


PROCEDURE check_duplicate_loc
IS

CURSOR c1 
IS
SELECT COUNT(1) cnt,
       location,
       process_mode,
       txn_type 
  FROM xx_fa_reval_loc_stg
 WHERE process_flag=1
 GROUP BY location,process_mode,txn_type
 HAVING COUNT(1)>1;

 
CURSOR c2(p_loc VARCHAR2, p_txn_type VARCHAR2,p_mode VARCHAR2)
IS
SELECT location,process_mode,txn_type 
  FROM xx_fa_reval_loc_stg
 WHERE process_flag=1
   AND location=p_loc
   AND process_mode=p_mode
   AND NVL(txn_type,'X')=NVL(p_txn_type,'X');
    
  i number:=0;    

BEGIN

  FOR cur IN c1 LOOP
    i:=0;
    FOR c in c2(cur.location,cur.txn_type,cur.process_mode) LOOP
        i:=i+1;
        IF i>1 THEN
        
          UPDATE xx_fa_reval_loc_stg
             SET process_flag=7
           WHERE process_flag=1
             AND location=cur.location
             AND NVL(txn_type,'X')=NVL(cur.txn_type,'X')
             AND process_mode=cur.process_mode
             AND ROWNUM<2;  
        
        END IF;    
    
    END LOOP;
  END LOOP;
  COMMIT;
EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error while checking duplicate locations : '||SQLERRM);  
END check_duplicate_loc;

PROCEDURE asset_revaluation( x_errbuf      OUT NOCOPY VARCHAR2
                            ,x_retcode     OUT NOCOPY VARCHAR2
			    ,p_txn_type	    	IN  VARCHAR2
			    ,p_process_mode IN VARCHAR2
  		           )
IS

CURSOR c_loc(p_request_id NUMBER) IS
SELECT *
  FROM xx_fa_reval_loc_stg
 WHERE request_id=p_request_id;

CURSOR c_asset(p_loc VARCHAR2)
IS
SELECT a.asset_id,	
       a.asset_number,							
       a.description,								
       b.book_type_code,								
       cc.segment1 company,								
       cc.segment4 building,								
       cc.segment2 costcenter,	
       cc.segment6 lob,								
       fcat.segment1 Major,								
       fcat.segment2 Minor,								
       fcat.segment3 Subminor							
  FROM gl_code_combinations cc,
       fa_categories_b fcat,
       fa_additions a,								
       fa_distribution_history b,	
       fa_locations fal						
 WHERE fal.segment5=LPAD(p_loc,6,'0')
   AND b.location_id=fal.location_id
   AND b.date_ineffective is null                          
   AND b.book_type_code='OD US CORP'
   AND a.asset_id=b.asset_id
   AND fcat.category_id=a.asset_category_id 
   AND cc.code_combination_id=b.code_combination_id
   AND fcat.segment1 IN (SELECT flex_value
			   FROM fnd_flex_values b,
			        Fnd_flex_value_sets a
			  WHERE flex_value_set_name='XX_FA_REVAL_CATEGORY'
			    AND b.flex_value_Set_id=a.flex_value_set_id
			    AND b.enabled_flag='Y');

CURSOR c_asset_detail(p_asset_id NUMBER) 
IS
SELECT fb.asset_id,								
       fb.date_placed_in_service,								
       fb.life_in_months,								
       fb.cost,								
       ds.deprn_amount,								
       ds.ytd_deprn,								
       ds.deprn_reserve,								
       fb.recoverable_cost								
  FROM FA_DEPRN_SUMMARY ds,							       
       fa_books_v fb	
 WHERE fb.asset_id=p_asset_id
   AND fb.book_type_code='OD US CORP'							
   AND ds.asset_id=fb.asset_id								
   AND ds.book_type_code=fb.book_type_code						
   AND DS.PERIOD_COUNTER = (SELECT max(DS1.PERIOD_COUNTER)				
                              FROM FA_DEPRN_SUMMARY DS1				
                             WHERE DS1.ASSET_ID=DS.ASSET_ID				
                               AND DS1.BOOK_TYPE_CODE = DS.BOOK_TYPE_CODE);		

CURSOR c_nbv(p_request_id NUMBER)
IS
SELECT *
  FROM xx_fa_reval_assets_stg
 WHERE request_id=p_request_id;


CURSOR c_reval(p_request_id NUMBER)
IS
SELECT *
  FROM xx_fa_reval_assets_stg
 WHERE request_id=p_request_id
   AND ( (nbv<>0) OR (cost<>0 and NBV=0) );


CURSOR c_check_preview(p_request_id NUMBER)
IS
SELECT location
  FROM xx_fa_reval_loc_stg a
 WHERE request_id=p_request_id
   AND process_mode='PREVIEW'
   AND txn_type=p_txn_type
   AND process_flag=1
   AND EXISTS (SELECT 'x'
		 FROM xx_fa_reval_loc_stg
		WHERE location=a.location
		  AND process_mode=a.process_mode
		  AND txn_type=a.txn_type
		  AND process_Flag=4);

CURSOR c_check_run(p_request_id NUMBER)
IS
SELECT location
  FROM xx_fa_reval_loc_stg a
 WHERE request_id=p_request_id
   AND process_flag=1
   AND process_mode='RUN'
   AND txn_type=p_txn_type
   AND NOT EXISTS (SELECT 'x'
		 FROM xx_fa_reval_loc_stg
		WHERE location=a.location
		  AND process_mode='PREVIEW'
		  AND txn_type=a.txn_type
		  AND process_Flag=4);


CURSOR c_update_preview(p_request_id NUMBER)
IS
SELECT location
  FROM xx_fa_reval_loc_stg a
 WHERE request_id=p_request_id
   AND process_flag=1
   AND process_mode='RUN'
   AND txn_type=p_txn_type
   AND EXISTS (SELECT 'x'
		 FROM xx_fa_reval_loc_stg
		WHERE location=a.location
		  AND process_mode='PREVIEW'
		  AND txn_type=a.txn_type
		  AND process_Flag=4);


v_request_id	NUMBER:=fnd_global.conc_request_id;
v_fa_period     VARCHAR2(25);
v_gl_period	VARCHAR2(25);
v_fa_rtdprd	VARCHAR2(25);
v_nbv		NUMBER:=0;
v_run_check	NUMBER:=0;
v_newcost	NUMBER:=0;
v_newnbv	NUMBER:=0;
v_impair_cost   NUMBER:=0;

v_deprn_open_period NUMBER;
BEGIN

  Update xx_fa_reval_loc_stg
     set process_flag=7
   where process_flag=1
     and (location is null or reval_pct is null or process_mode is null);
  commit;

  purge_proc;

  check_duplicate_loc;

  UPDATE xx_fa_reval_loc_stg
     SET request_id=v_request_id
	,txn_type=p_txn_type
   WHERE process_Flag=1
     AND process_mode=p_process_mode;
  COMMIT;

  FOR cur IN c_check_preview(v_request_id) LOOP

    UPDATE xx_fa_reval_loc_stg
       SET process_flag=7
     WHERE location=cur.location
       AND txn_type=p_txn_type
       AND process_Flag=4;

  END LOOP;
  COMMIT;

  fnd_file.put_line(fnd_file.LOG, 'After c_check_preview');

  IF p_process_mode='RUN' THEN

     FOR cur IN c_check_run(v_request_id) LOOP

       v_run_check:=v_run_check+1;
  
       fnd_file.put_line(fnd_file.LOG, 'PREVIEW was not completed for Assets with this Location : '||cur.location);

     END LOOP;

     IF v_run_check>0 THEN
        UPDATE xx_fa_reval_loc_stg
           SET process_flag=7
        WHERE request_id=v_request_id
	  AND txn_type=p_txn_type;
        COMMIT;

        x_errbuf:='PREVIEW was not completed for Locations specified for RUN mode';
        x_retcode:=2;
        RETURN;
     END IF;

     FOR cur IN c_update_preview(v_request_id) LOOP

        UPDATE xx_fa_reval_loc_stg
           SET process_flag=7
        WHERE location=cur.location
	  AND txn_type=p_txn_type;
        COMMIT;

     END LOOP;
  
  END IF;

  FOR c IN C_loc(v_request_id) LOOP

    FOR cur IN c_asset(c.location) LOOP

	BEGIN
	  SELECT b.period_name
	    INTO v_fa_rtdprd
	    from fa_calendar_periods b,
		 fa_transaction_headers a
	   where a.asset_id=cur.asset_id
	     and a.transaction_type_code='FULL RETIREMENT'
	     and a.book_type_code='OD US CORP'
	     and a.date_effective between b.start_date and b.end_date;
	EXCEPTION
	  WHEN others THEN
	    v_fa_rtdprd:=NULL;
	END;

	BEGIN
	  select period_name 
	    INTO v_fa_period	
  	    from fa_calendar_periods
	   where TRUNC(SYSDATE) between start_date and end_date
	     AND calendar_type='OD_ALL_MONTH';
	EXCEPTION
	  WHEN others THEN
	    v_fa_period:=NULL;
	END;

	FOR cur1 IN c_asset_detail(cur.asset_id) LOOP

	  BEGIN
	    Select period_name
	      INTO v_gl_period
	      From gl_periods
	     Where period_set_name='OD 445 CALENDAR'
	       And cur1.date_placed_in_service between start_date and end_date;
	  EXCEPTION
	    WHEN others THEN
	      v_gl_period:=NULL;
	  END;	
	  BEGIN
	    INSERT
	      INTO xx_fa_reval_assets_stg
		  ( 	 asset_id
			,asset_no
			,description
			,book_type_code
			,location
			,process_mode
			,reval_pct
			,txn_type
			,company
			,building
			,costcenter
			,lob
			,major
			,minor
			,subminor
			,date_placed_in_service
			,life_in_months
			,fa_period
			,fa_retired_period
			,gl_period
			,cost
			,deprn_amount
			,ytd_deprn
			,deprn_reserve
			,creation_date
			,created_by
			,last_update_date
			,last_updated_by
			,process_flag
			,request_id
			,error_flag
		 )
	    VALUES
		(	 cur.asset_id
			,cur.asset_number
			,cur.description
			,cur.book_type_code
			,c.location
			,c.process_mode
			,TO_NUMBER(c.reval_pct)
			,p_txn_type
			,cur.company
			,cur.building
			,cur.costcenter
			,cur.lob
			,cur.major
			,cur.minor
			,cur.subminor
			,cur1.date_placed_in_service
			,cur1.life_in_months
			,v_fa_period
			,v_fa_rtdprd	
			,v_gl_period
			,cur1.cost
			,cur1.deprn_amount
			,cur1.ytd_deprn
			,cur1.deprn_reserve
			,sysdate
			,fnd_global.user_id
			,sysdate
			,fnd_global.user_id
			,1
			,c.request_id,'N'
		);
	  EXCEPTION
	    WHEN others THEN
	      fnd_file.put_line(fnd_file.LOG, 'Error While inserting asset stg table for Asset :'||
		  cur.asset_number ||','||sqlerrm);
	  END;
	END LOOP;
    END LOOP;
    COMMIT;
  END LOOP;  

  fnd_file.put_line(fnd_file.LOG, 'After insertion in xx_fa_reval_assets_stg');

  FOR cur IN c_nbv(v_request_id) LOOP

    v_nbv:=get_nbv(cur.asset_id,cur.cost,cur.book_type_code);
	
	-- START : Code added to add back  the depreciation of open period in PREVIEW mode only. QC Defect - 26624
	IF p_process_mode = 'PREVIEW' then

	   BEGIN
	     SELECT NVL(SUM(deprn_amount),0)
	       INTO v_deprn_open_period
	       FROM FA_DEPRN_SUMMARY ds
	      WHERE asset_id=cur.asset_id 
		AND book_type_code=cur.book_type_code
		AND period_counter in (select dp.period_counter
				         from  fa_deprn_periods dp,
					       fa_deprn_periods dp2,
				               fa_deprn_periods dp3,
				               fa_book_controls bc
				        where  dp.book_type_code = cur.book_type_code
					  and  dp.period_close_date is null	
				          and  dp2.book_type_code(+) = bc.distribution_source_book
					  and  dp2.period_counter(+) = bc.last_mass_copy_period_counter
					  and  dp3.book_type_code(+) = bc.book_type_code
					  and  dp3.period_counter(+) = bc.last_purge_period_counter
					  and  bc.book_type_code = cur.book_type_code);
    	   EXCEPTION
	     WHEN OTHERS THEN
	       fnd_file.put_line(fnd_file.LOG, 'Error in getting the depreciation amount for open period');
	       v_deprn_open_period :=0;
	   END;
	   v_nbv := v_nbv + NVL(v_deprn_open_period,0);
	END IF;
    
	-- END : Code added to add back  the depreciation of open period in PREVIEW mode only. QC Defect - 26624

    UPDATE xx_fa_reval_assets_stg
       SET nbv=v_nbv,
	   ytd_deprn=ytd_deprn-NVL(v_deprn_open_period,0),  -- Defect 28153
	   deprn_reserve=deprn_reserve-NVL(v_deprn_open_period,0)  -- Defect 28153
     WHERE asset_id=cur.asset_id
       AND request_id=v_request_id;     
 
  END LOOP;

  fnd_file.put_line(fnd_file.LOG, 'After nbv calculation');

  UPDATE XX_FA_REVAL_ASSETS_STG 
     SET reval_pct=-100
   WHERE request_id=v_request_id
     AND cost<>0 
     AND nbv=0;
  COMMIT;

  IF p_process_mode='PREVIEW' THEN

     FOR cur IN c_reval(v_request_id) LOOP

       xx_asset_reval_api(cur.asset_id,cur.reval_pct,cur.book_type_code,cur.process_mode,v_request_id);

     END LOOP;

     Update xx_fa_reval_assets_stg 	
	set imp_cost=NVL(new_cost,0)-NVL(nbv,0)
      where request_id=v_request_id;
     COMMIT;


     fnd_file.put_line(fnd_file.LOG, 'In Preview, After calculation preview');

     submit_preview_reports(v_request_id);

     fnd_file.put_line(fnd_file.LOG, 'After submitting reports');
 
     Update xx_fa_reval_loc_stg 	
	set process_Flag=4 
      where request_id=v_request_id;

     Update xx_fa_reval_assets_stg 
        set process_Flag=7
      where request_id=v_request_id;
	
     COMMIT;

  END IF;

  IF p_process_mode='RUN' THEN

     FOR cur IN c_reval(v_request_id) LOOP

       xx_asset_reval_api(cur.asset_id,cur.reval_pct,cur.book_type_code,cur.process_mode,v_request_id);

     END LOOP;


     FOR cur IN c_reval(v_request_id) LOOP

       v_newcost:=0;
       v_impair_cost:=0;

       BEGIN
         SELECT NVL(fb.cost,0)
	   INTO v_newcost
	   FROM fa_books fb                       
          WHERE fb.asset_id=cur.asset_id                            
            AND fb.book_type_code='OD US CORP'
            AND fb.date_ineffective IS NULL;
       EXCEPTION
	 WHEN others THEN
	   v_newcost:=NULL;
	   v_impair_cost:=NULL;
       END;                            

       v_newnbv:=get_nbv(cur.asset_id,v_newcost,cur.book_type_code);


       BEGIN
	 SELECT Decode(debit_credit_flag,'DR',adjustment_amount*-1,'CR',adjustment_amount) adj_amnt
	   INTO v_impair_cost
	   FROM fa_adjustments a
          WHERE a.asset_id=cur.asset_id
	    AND a.book_type_code='OD US CORP'
	    AND a.source_type_code='REVALUATION' 
	    AND a.adjustment_type='REVAL RESERVE'
	    AND TRUNC(a.last_update_date)>TRUNC(SYSDATE-1)
	    AND a.transaction_header_id=(SELECT MAX(transaction_header_id)
                   		           FROM fa_adjustments
                            		  WHERE asset_id=a.asset_id
                             		    AND book_type_code=a.book_type_code
                             		    AND source_type_code=a.source_type_code
					    AND TRUNC(last_update_date)>TRUNC(SYSDATE-1)
                             		    AND adjustment_type=a.adjustment_type);
       EXCEPTION
	 WHEN others THEN
	   v_impair_cost:=0;
       END;

       UPDATE xx_fa_reval_assets_stg
	  SET new_cost=v_newcost,
	      new_nbv=v_newnbv,
	      imp_cost=v_impair_cost
	WHERE asset_id=cur.asset_id
          AND request_id=v_request_id;

     END LOOP;
     COMMIT;	

     submit_run_reports(v_request_id);

     Update xx_fa_reval_loc_stg 	
	set process_Flag=7
      where request_id=v_request_id;

     Update xx_fa_reval_assets_stg 
        set process_Flag=7
      where request_id=v_request_id;

     COMMIT;
  END IF;
 
EXCEPTION
  WHEN others THEN 
    x_errbuf:=SQLERRM;
    x_retcode:=2;      
END asset_revaluation;


PROCEDURE check_duplicate_asset
IS

CURSOR c1 
IS
SELECT COUNT(1) cnt,
       asset_id,
       process_mode,
       txn_type 
  FROM xx_fa_rvl_by_asset
 WHERE process_flag=1
 GROUP BY asset_id,process_mode,txn_type
 HAVING COUNT(1)>1;

 
CURSOR c2(p_asset_id VARCHAR2, p_txn_type VARCHAR2,p_mode VARCHAR2)
IS
SELECT asset_id,process_mode,txn_type 
  FROM xx_fa_rvl_by_asset
 WHERE process_flag=1
   AND asset_id=p_asset_id
   AND process_mode=p_mode
   AND NVL(txn_type,'X')=NVL(p_txn_type,'X');
    
  i number:=0;    

BEGIN

  FOR cur IN c1 LOOP
    i:=0;
    FOR c in c2(cur.asset_id,cur.txn_type,cur.process_mode) LOOP
        i:=i+1;
        IF i>1 THEN
        
          UPDATE xx_fa_rvl_by_asset
             SET process_flag=7
           WHERE process_flag=1
             AND asset_id=cur.asset_id
             AND NVL(txn_type,'X')=NVL(cur.txn_type,'X')
             AND process_mode=cur.process_mode
             AND ROWNUM<2;  
        
        END IF;    
    
    END LOOP;
  END LOOP;
  COMMIT;
EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error while checking duplicate asset_id : '||SQLERRM);  
END check_duplicate_asset;

PROCEDURE reval_by_asset ( x_errbuf      	OUT NOCOPY VARCHAR2
                          ,x_retcode     	OUT NOCOPY VARCHAR2
			  ,p_txn_type	    	IN  VARCHAR2
			  ,p_process_mode 	IN  VARCHAR2
  		         )
IS

CURSOR c_stg(p_request_id NUMBER) IS
SELECT *
  FROM xx_fa_rvl_by_asset
 WHERE request_id=p_request_id;


CURSOR c_asset(p_asset_id NUMBER)
IS
SELECT a.asset_id,	
       a.asset_number,							
       a.description,								
       b.book_type_code,								
       cc.segment1 company,								
       cc.segment4 building,								
       cc.segment2 costcenter,	
       cc.segment6 lob,								
       fcat.segment1 Major,								
       fcat.segment2 Minor,								
       fcat.segment3 Subminor,
       fal.segment5 location
  FROM gl_code_combinations cc,
       fa_categories_b fcat,
       fa_locations fal,						
       fa_distribution_history b,	
       fa_additions a								
 WHERE a.asset_id=p_asset_id
   AND b.asset_id=a.asset_id
   AND b.date_ineffective is null                          
   AND b.book_type_code='OD US CORP'
   AND fal.location_id=b.location_id
   AND fcat.category_id=a.asset_category_id 
   AND cc.code_combination_id=b.code_combination_id
   AND fcat.segment1 IN (SELECT flex_value
			   FROM fnd_flex_values b,
			        Fnd_flex_value_sets a
			  WHERE flex_value_set_name='XX_FA_REVAL_CATEGORY'
			    AND b.flex_value_Set_id=a.flex_value_set_id
			    AND b.enabled_flag='Y');
CURSOR c_asset_detail(p_asset_id NUMBER) 
IS
SELECT fb.asset_id,								
       fb.date_placed_in_service,								
       fb.life_in_months,								
       fb.cost,								
       ds.deprn_amount,								
       ds.ytd_deprn,								
       ds.deprn_reserve,								
       fb.recoverable_cost								
  FROM FA_DEPRN_SUMMARY ds,							       
       fa_books_v fb	
 WHERE fb.asset_id=p_asset_id
   AND fb.book_type_code='OD US CORP'							
   AND ds.asset_id=fb.asset_id								
   AND ds.book_type_code=fb.book_type_code						
   AND DS.PERIOD_COUNTER = (SELECT max(DS1.PERIOD_COUNTER)				
                              FROM FA_DEPRN_SUMMARY DS1				
                             WHERE DS1.ASSET_ID=DS.ASSET_ID				
                               AND DS1.BOOK_TYPE_CODE = DS.BOOK_TYPE_CODE);		

CURSOR c_nbv(p_request_id NUMBER)
IS
SELECT *
  FROM xx_fa_reval_assets_stg
 WHERE request_id=p_request_id;


CURSOR c_reval(p_request_id NUMBER)
IS
SELECT *
  FROM xx_fa_reval_assets_stg
 WHERE request_id=p_request_id
   AND ( (nbv<>0) OR (cost<>0 and NBV=0) );


CURSOR c_check_preview(p_request_id NUMBER)
IS
SELECT asset_id
  FROM xx_fa_rvl_by_asset a
 WHERE request_id=p_request_id
   AND process_mode='PREVIEW'
   AND txn_type=p_txn_type
   AND process_flag=1
   AND EXISTS (SELECT 'x'
		 FROM xx_fa_rvl_by_asset
		WHERE asset_id=a.asset_id
		  AND process_mode=a.process_mode
		  AND txn_type=a.txn_type
		  AND process_Flag=4);

CURSOR c_check_run(p_request_id NUMBER)
IS
SELECT asset_id
  FROM xx_fa_rvl_by_asset a
 WHERE request_id=p_request_id
   AND process_flag=1
   AND process_mode='RUN'
   AND txn_type=p_txn_type
   AND NOT EXISTS (SELECT 'x'
		 FROM xx_fa_rvl_by_asset
		WHERE asset_id=a.asset_id
		  AND process_mode='PREVIEW'
		  AND txn_type=a.txn_type
		  AND process_Flag=4);


CURSOR c_update_preview(p_request_id NUMBER)
IS
SELECT asset_id
  FROM xx_fa_rvl_by_asset a
 WHERE request_id=p_request_id
   AND process_flag=1
   AND process_mode='RUN'
   AND txn_type=p_txn_type
   AND EXISTS (SELECT 'x'
		 FROM xx_fa_rvl_by_asset
		WHERE asset_id=a.asset_id
		  AND process_mode='PREVIEW'
		  AND txn_type=a.txn_type
		  AND process_Flag=4);


v_request_id	NUMBER:=fnd_global.conc_request_id;
v_fa_period     VARCHAR2(25);
v_gl_period	VARCHAR2(25);
v_fa_rtdprd	VARCHAR2(25);
v_nbv		NUMBER:=0;
v_run_check	NUMBER:=0;
v_newcost	NUMBER:=0;
v_newnbv	NUMBER:=0;
v_impair_cost   NUMBER:=0;
i 		NUMBER:=0;

v_deprn_open_period NUMBER;
BEGIN

  Update xx_fa_rvl_by_asset
     set process_flag=7
   where process_flag=1
     and (asset_id is null or reval_pct is null or process_mode is null);
  commit;

  purge_proc;

  check_duplicate_asset;

  UPDATE xx_fa_rvl_by_asset
     SET request_id=v_request_id
	,txn_type=p_txn_type
   WHERE process_Flag=1
     AND process_mode=p_process_mode;
  COMMIT;

  FOR cur IN c_check_preview(v_request_id) LOOP

    UPDATE xx_fa_rvl_by_asset
       SET process_flag=7
     WHERE asset_id=cur.asset_id
       AND txn_type=p_txn_type
       AND process_Flag=4;

  END LOOP;
  COMMIT;

  fnd_file.put_line(fnd_file.LOG, 'After c_check_preview');

  IF p_process_mode='RUN' THEN

     FOR cur IN c_check_run(v_request_id) LOOP

       v_run_check:=v_run_check+1;
  
       fnd_file.put_line(fnd_file.LOG, 'PREVIEW was not completed for Assets  : '||cur.asset_id);

     END LOOP;

     IF v_run_check>0 THEN
        UPDATE xx_fa_rvl_by_asset
           SET process_flag=7
        WHERE request_id=v_request_id
	  AND txn_type=p_txn_type;
        COMMIT;

        x_errbuf:='PREVIEW was not completed for Assets specified for RUN mode';
        x_retcode:=2;
        RETURN;
     END IF;

     FOR cur IN c_update_preview(v_request_id) LOOP

        UPDATE xx_fa_rvl_by_asset
           SET process_flag=7
        WHERE asset_id=cur.asset_id
	  AND txn_type=p_txn_type;
        COMMIT;

     END LOOP;
  
  END IF;

  FOR c IN C_stg(v_request_id) LOOP
 
    i:=0;
  
    FOR cur IN c_asset(TO_NUMBER(c.asset_id)) LOOP

       i:=i+1;

	BEGIN
	  SELECT b.period_name
	    INTO v_fa_rtdprd
	    from fa_calendar_periods b,
		 fa_transaction_headers a
	   where a.asset_id=cur.asset_id
	     and a.transaction_type_code='FULL RETIREMENT'
	     and a.book_type_code='OD US CORP'
	     and a.date_effective between b.start_date and b.end_date;
	EXCEPTION
	  WHEN others THEN
	    v_fa_rtdprd:=NULL;
	END;

	BEGIN
	  select period_name 
	    INTO v_fa_period	
  	    from fa_calendar_periods
	   where TRUNC(SYSDATE) between start_date and end_date
	     AND calendar_type='OD_ALL_MONTH';
	EXCEPTION
	  WHEN others THEN
	    v_fa_period:=NULL;
	END;

	FOR cur1 IN c_asset_detail(TO_NUMBER(cur.asset_id)) LOOP

	  BEGIN
	    Select period_name
	      INTO v_gl_period
	      From gl_periods
	     Where period_set_name='OD 445 CALENDAR'
	       And cur1.date_placed_in_service between start_date and end_date;
	  EXCEPTION
	    WHEN others THEN
	      v_gl_period:=NULL;
	  END;	
	  BEGIN
	    INSERT
	      INTO xx_fa_reval_assets_stg
		  ( 	 asset_id
			,asset_no
			,description
			,book_type_code
			,location
			,process_mode
			,reval_pct
			,txn_type
			,company
			,building
			,costcenter
			,lob
			,major
			,minor
			,subminor
			,date_placed_in_service
			,life_in_months
			,fa_period
			,fa_retired_period
			,gl_period
			,cost
			,deprn_amount
			,ytd_deprn
			,deprn_reserve
			,creation_date
			,created_by
			,last_update_date
			,last_updated_by
			,process_flag
			,request_id
			,error_flag
		 )
	    VALUES
		(	 cur.asset_id
			,cur.asset_number
			,cur.description
			,cur.book_type_code
			,cur.location
			,c.process_mode
			,TO_NUMBER(c.reval_pct)
			,p_txn_type
			,cur.company
			,cur.building
			,cur.costcenter
			,cur.lob
			,cur.major
			,cur.minor
			,cur.subminor
			,cur1.date_placed_in_service
			,cur1.life_in_months
			,v_fa_period
			,v_fa_rtdprd	
			,v_gl_period
			,cur1.cost
			,cur1.deprn_amount
			,cur1.ytd_deprn
			,cur1.deprn_reserve
			,sysdate
			,fnd_global.user_id
			,sysdate
			,fnd_global.user_id
			,1
			,c.request_id,'N'
		);
	  EXCEPTION
	    WHEN others THEN
	      fnd_file.put_line(fnd_file.LOG, 'Error While inserting asset stg table for Asset :'||
		  cur.asset_number ||','||sqlerrm);
	  END;
	END LOOP;
    END LOOP;
    IF i=0 THEN
	
       BEGIN
         INSERT
	      INTO xx_fa_reval_assets_stg    
		(asset_id,asset_no,error_flag,error_message,request_id)
	    VALUES
	        (c.asset_id,c.asset_id,'Y','Unable to derive asset details',c.request_id);
       EXCEPTION
         WHEN others THEN
	   NULL;
       END;

    END IF;


    COMMIT;
  END LOOP;  

  fnd_file.put_line(fnd_file.LOG, 'After insertion in xx_fa_reval_assets_stg');

  FOR cur IN c_nbv(v_request_id) LOOP

    v_nbv:=get_nbv(cur.asset_id,cur.cost,cur.book_type_code);
	
	-- START : Code added to add back  the depreciation of open period in PREVIEW mode only. QC Defect - 26624
	IF p_process_mode = 'PREVIEW' then

	   BEGIN
	     SELECT NVL(SUM(deprn_amount),0)
	       INTO v_deprn_open_period
	       FROM FA_DEPRN_SUMMARY ds
	      WHERE asset_id=cur.asset_id 
		AND book_type_code=cur.book_type_code
		AND period_counter in (select dp.period_counter
				         from  fa_deprn_periods dp,
					       fa_deprn_periods dp2,
				               fa_deprn_periods dp3,
				               fa_book_controls bc
				        where  dp.book_type_code = cur.book_type_code
					  and  dp.period_close_date is null	
				          and  dp2.book_type_code(+) = bc.distribution_source_book
					  and  dp2.period_counter(+) = bc.last_mass_copy_period_counter
					  and  dp3.book_type_code(+) = bc.book_type_code
					  and  dp3.period_counter(+) = bc.last_purge_period_counter
					  and  bc.book_type_code = cur.book_type_code);
    	   EXCEPTION
	     WHEN OTHERS THEN
	       fnd_file.put_line(fnd_file.LOG, 'Error in getting the depreciation amount for open period');
	       v_deprn_open_period :=0;
	   END;
	   v_nbv := v_nbv + NVL(v_deprn_open_period,0);
	END IF;
    
	-- END : Code added to add back  the depreciation of open period in PREVIEW mode only. QC Defect - 26624

    UPDATE xx_fa_reval_assets_stg
       SET nbv=v_nbv,
	   ytd_deprn=ytd_deprn-NVL(v_deprn_open_period,0),  -- Defect 28153
	   deprn_reserve=deprn_reserve-NVL(v_deprn_open_period,0)  -- Defect 28153
     WHERE asset_id=cur.asset_id
       AND request_id=v_request_id;     
 
  END LOOP;

  fnd_file.put_line(fnd_file.LOG, 'After nbv calculation');

  UPDATE XX_FA_REVAL_ASSETS_STG 
     SET reval_pct=-100
   WHERE request_id=v_request_id
     AND cost<>0 
     AND nbv=0;
  COMMIT;

  IF p_process_mode='PREVIEW' THEN

     FOR cur IN c_reval(v_request_id) LOOP

       xx_asset_reval_api(cur.asset_id,cur.reval_pct,cur.book_type_code,cur.process_mode,v_request_id);

     END LOOP;

     Update xx_fa_reval_assets_stg 	
	set imp_cost=NVL(new_cost,0)-NVL(nbv,0)
      where request_id=v_request_id;
     COMMIT;


     fnd_file.put_line(fnd_file.LOG, 'In Preview, After calculation preview');

     submit_preview_reports(v_request_id);

     fnd_file.put_line(fnd_file.LOG, 'After submitting reports');
 
     Update xx_fa_rvl_by_asset
	set process_Flag=4 
      where request_id=v_request_id;

     Update xx_fa_reval_assets_stg 
        set process_Flag=7
      where request_id=v_request_id;
	
     COMMIT;

  END IF;

  IF p_process_mode='RUN' THEN

     FOR cur IN c_reval(v_request_id) LOOP

       xx_asset_reval_api(cur.asset_id,cur.reval_pct,cur.book_type_code,cur.process_mode,v_request_id);

     END LOOP;


     FOR cur IN c_reval(v_request_id) LOOP

       v_newcost:=0;
       v_impair_cost:=0;

       BEGIN
         SELECT NVL(fb.cost,0)
	   INTO v_newcost
	   FROM fa_books fb                       
          WHERE fb.asset_id=cur.asset_id                            
            AND fb.book_type_code='OD US CORP'
            AND fb.date_ineffective IS NULL;
       EXCEPTION
	 WHEN others THEN
	   v_newcost:=NULL;
	   v_impair_cost:=NULL;
       END;                            

       v_newnbv:=get_nbv(cur.asset_id,v_newcost,cur.book_type_code);


       BEGIN
	 SELECT Decode(debit_credit_flag,'DR',adjustment_amount*-1,'CR',adjustment_amount) adj_amnt
	   INTO v_impair_cost
	   FROM fa_adjustments a
          WHERE a.asset_id=cur.asset_id
	    AND a.book_type_code='OD US CORP'
	    AND a.source_type_code='REVALUATION' 
	    AND a.adjustment_type='REVAL RESERVE'
	    AND TRUNC(a.last_update_date)>TRUNC(SYSDATE-1)
	    AND a.transaction_header_id=(SELECT MAX(transaction_header_id)
                   		           FROM fa_adjustments
                            		  WHERE asset_id=a.asset_id
                             		    AND book_type_code=a.book_type_code
                             		    AND source_type_code=a.source_type_code
					    AND TRUNC(last_update_date)>TRUNC(SYSDATE-1)
                             		    AND adjustment_type=a.adjustment_type);
       EXCEPTION
	 WHEN others THEN
	   v_impair_cost:=0;
       END;

       UPDATE xx_fa_reval_assets_stg
	  SET new_cost=v_newcost,
	      new_nbv=v_newnbv,
	      imp_cost=v_impair_cost
	WHERE asset_id=cur.asset_id
          AND request_id=v_request_id;

     END LOOP;
     COMMIT;	

     submit_run_reports(v_request_id);

     Update xx_fa_rvl_by_asset	
	set process_Flag=7
      where request_id=v_request_id;

     Update xx_fa_reval_assets_stg 
        set process_Flag=7
      where request_id=v_request_id;

     COMMIT;
  END IF;
 
EXCEPTION
  WHEN others THEN 
    x_errbuf:=SQLERRM;
    x_retcode:=2;      
END reval_by_asset;

END XX_FA_MASS_REVAL_PKG;
/
