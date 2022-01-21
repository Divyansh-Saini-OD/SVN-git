SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON                              
PROMPT Creating Package Body XX_FA_MASS_UNP_DEPRN_PKG
Prompt Program Exits If The Creation Is Not Successful
WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE PACKAGE BODY XX_FA_MASS_UNP_DEPRN_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_FA_MASS_UNP_DEPRN_PKG.pkb	                     |
-- | Description :  OD FA Mass Unplanned Depriciation                  |
-- | RICE ID     :  E3122 (Defect#35047)                               |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       16-Jul-2015 Madhu Bolli        Initial version           |
-- |1.1       28-Aug-2015 Paddy Sanjeevi     Defect 35674              |
-- |1.2       25-Sep-2015 Paddy Sanjeevi     Multi-threading           |
-- |1.3       30-Oct-2015 Madhu Bolli        122 Retrofit - Remove schema |
-- +===================================================================+
AS

-- +====================================================================+
-- | Name        :  display_output                                      |
-- | Description :  This procedure is to display the records success,   | 
-- |                error and error records with error message          |
-- |                                                                    |
-- | Parameters  :  p_request_id, p_process_mode                        |
-- +====================================================================+

procedure display_output(p_request_id IN VARCHAR2, p_process_mode IN VARCHAR2)
IS
--==============================================================================
-- Cursor Declarations to get table statistics of FA MM Adjustments Staging
--==============================================================================
      CURSOR c_fa_mm_adj_stats(c_request_id NUMBER)
      IS
          SELECT NVL(SUM(1), 0)                -- Total Processed records
            ,NVL(SUM(DECODE(PROCESS_FLAG,DECODE(p_process_mode, 'PREVIEW', 4, 7),1,0)), 0)   -- Successfully Validated and adjusted
            ,NVL(SUM(DECODE(PROCESS_FLAG,3,1,6,1,0)), 0)    -- Errored Records
          FROM  xx_fa_unp_deprn_stg
          WHERE request_id = c_request_id;
--==============================================================================
-- Cursor Declarations to get the error list of FA MM Adjustments Staging
--==============================================================================
      CURSOR c_fa_err_list(c_request_id NUMBER)
      IS
          SELECT asset_id, book_type_code, error_message
          FROM  xx_fa_unp_deprn_stg
          WHERE (process_flag = 3 or process_flag = 6)
            AND request_id   = c_request_id; 
    l_eligible_cnt    NUMBER;
    l_processed_cnt   NUMBER;
    l_success_cnt     NUMBER;
    l_errored_cnt     NUMBER;
    v_cnt             NUMBER;
  BEGIN           
      l_eligible_cnt := 0;
      l_processed_cnt := 0;
      l_success_cnt  := 0;
      l_errored_cnt  := 0;
      OPEN  c_fa_mm_adj_stats(p_request_id);
      FETCH c_fa_mm_adj_stats INTO l_processed_cnt, l_success_cnt, l_errored_cnt;
      CLOSE c_fa_mm_adj_stats;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'--------------------------------------------------------------------------------------------');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Records to be processed         :  '||l_processed_cnt);
      
      IF  p_process_mode = 'PREVIEW' THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Records Successfully Validated  :  '||l_success_cnt);
      ELSIF p_process_mode = 'RUN' THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Records Successfully Processed  :  '||l_success_cnt);
      END IF;
      
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Failed Records                  :  '||l_errored_cnt);  
      FND_FILE.PUT_LINE(FND_FILE.LOG,'--------------------------------------------------------------------------------------------');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'--------------------------------------------------------------------------------------------');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Records to be processed         :  '||l_processed_cnt);
      
      IF  p_process_mode = 'PREVIEW' THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Records Successfully Validated  :  '||l_success_cnt);
      ELSIF p_process_mode = 'RUN' THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Records Successfully Processed  :  '||l_success_cnt);
      END IF;
            
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Failed Records                  :  '||l_errored_cnt);    
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'--------------------------------------------------------------------------------------------');
      IF l_errored_cnt > 0 THEN
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Failed Record details');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'S.No, Book Type, Asset Number, Error Message');
        v_cnt := 0;
        FOR CUR IN c_fa_err_list(p_request_id) LOOP
          v_cnt:=v_cnt+1;
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD(v_cnt,6)||'. '||cur.book_type_code||','||cur.asset_id||','||cur.error_message);      
        END LOOP;
      END IF;
EXCEPTION
  WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.LOG, 'Error in Purging Processed Records : '||SQLERRM);
END display_output;

-- +====================================================================+
-- | Name        :  derive_amortz                                       |
-- | Description :  This procedure is to derive amortization for asset  |
-- |                                                                    |
-- | Parameters  :  asset_id, book                                      |
-- +====================================================================+
FUNCTION  derive_amortz( p_asset_id     IN NUMBER
                        ,p_book_type    IN VARCHAR2
		       )
RETURN VARCHAR2
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


l_trx_date           	DATE;
l_cal_per_close_date 	DATE;
l_amortized  	  	VARCHAR2(1);
l_amortize_adj   	VARCHAR2(3);




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
  RETURN(l_amortize_adj);
EXCEPTION
  WHEN others THEN
    fnd_file.put_line(fnd_file.LOG, 'When others while deriving amortization for the asset : '||TO_CHAR(p_asset_id)||','||
				    SQLERRM);
END derive_amortz;



-- +====================================================================+
-- | Name        :  purge_proc                                          |
-- | Description :  This procedure is to purge the processed records    |
-- |                in the custom table xx_fa_unp_deprn_stg             |
-- | Parameters  :                                                      |
-- +====================================================================+


PROCEDURE purge_proc
IS


CURSOR C1
IS
SELECT rowid drowid
  FROM xx_fa_unp_deprn_stg
 WHERE (process_Flag=7 OR process_Flag=3 OR process_Flag=6)
   AND creation_date<SYSDATE-30;

i NUMBER:=0;

BEGIN

  FOR cur IN C1 LOOP

    i:=i+1;
    IF i>=5000 THEN
       COMMIT;
       i:=0;
    END IF;
   
    DELETE
      FROM xx_fa_unp_deprn_stg
     WHERE rowid=cur.drowid;

  END LOOP;
  COMMIT;
EXCEPTION
  WHEN others THEN
    fnd_file.put_line(fnd_file.LOG, 'Error in Purging Processed Records : '||SQLERRM);
END purge_proc;
 
-- +====================================================================+
-- | Name        :  xx_fa_unplan_depr_api                               |
-- | Description :  This procedure is to do unplanned depriciation by calling api |
-- |                                                                    |
-- | Parameters  :  asset_id, life, book, unplanned CCID, unplanned amt,|
-- |                unplanned type, request_id                          |
-- +====================================================================+

PROCEDURE xx_fa_unplan_depr_api(
			         	    p_asset_id 		  IN NUMBER
					    ,p_book_type    	IN VARCHAR2
     				         ,p_unp_dep_ccid   IN NUMBER
			              ,p_unp_amt        IN NUMBER
			              ,p_unp_type       IN VARCHAR2
			              ,p_batch_id 		IN NUMBER
					   )              
IS

  l_trans_rec             FA_API_TYPES.trans_rec_type;
  l_asset_hdr_rec 		    FA_API_TYPES.asset_hdr_rec_type;
  l_unplanned_deprn_rec 	FA_API_TYPES.unplanned_deprn_rec_type;

  l_return_status 		VARCHAR2(1);
  l_mesg_count 			  NUMBER;
  l_mesg 		          VARCHAR2(4000);
  l_msg				        VARCHAR2(512);

  l_error_msg         VARCHAR2(1700);
  l_amortized_flag	VARCHAR2(3);

begin

  FA_SRVR_MSG.Init_Server_Message;
  FA_DEBUG_PKG.Initialize;

  l_amortized_Flag:=derive_amortz( p_asset_id,p_book_type);


  -- asset header info
  l_asset_hdr_rec.asset_id        := p_asset_id;
  l_asset_hdr_rec.book_type_code  := p_book_type;


  IF l_amortized_Flag like 'Y%' THEN
 
     l_trans_rec.transaction_subtype := 'AMORTIZED';
     l_trans_rec.amortization_start_date := NULL;

  END IF;

  -- Unplanned info
  l_unplanned_deprn_rec.code_combination_id 	 := NVL(p_unp_dep_ccid, l_unplanned_deprn_rec.code_combination_id);
  l_unplanned_deprn_rec.unplanned_amount	     := NVL(p_unp_amt, p_unp_amt);
  l_unplanned_deprn_rec.unplanned_type 		     := NVL(p_unp_type, p_unp_type);

  FA_UNPLANNED_PUB.do_unplanned
	(p_api_version             => 1.0,
	 p_init_msg_list           => FND_API.G_FALSE,
	 p_commit                  => FND_API.G_FALSE,
	 p_validation_level        => FND_API.G_VALID_LEVEL_FULL,
	 p_calling_fn              => null,
	 x_return_status           => l_return_status,
	 x_msg_count               => l_mesg_count,
	 x_msg_data                => l_mesg,
	 px_trans_rec              => l_trans_rec,
	 px_asset_hdr_rec          => l_asset_hdr_rec,
	 p_unplanned_deprn_rec     => l_unplanned_deprn_rec
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
            
      ROLLBACK;   -- It rollback's all updates made(using this API) for all assets invoked before invoking this API for this asset
      
        UPDATE xx_fa_unp_deprn_stg
           SET error_flag='Y',
           process_flag = 6,
	       error_message=error_message||' : '||SUBSTR(l_mesg,1,1500)
         WHERE asset_id=p_asset_id
  	      AND batch_id+0=p_batch_id
	      AND book_type_code=p_book_type; 
         
         COMMIT;   

   ELSE
     COMMIT;      
   END IF;

EXCEPTION
 WHEN others THEN
   l_error_msg := SUBSTR(SQLERRM,1,1500);
   FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error while Asset Unplanned Depriciation :'||p_asset_id|| ','||l_error_msg);
   
   ROLLBACK;

   UPDATE xx_fa_unp_deprn_stg
   SET error_flag='Y',
       process_flag = 6,
	     error_message=error_message||',Exception - '||l_error_msg
   WHERE asset_id=p_asset_id
     AND batch_id+0=p_batch_id
	   AND book_type_code=p_book_type;
     
    COMMIT; 
END xx_fa_unplan_depr_api;


-- +====================================================================+
-- | Name        :  fa_unplanned_deprication                            |
-- | Description :  This procedure is to process the assets for         |
-- |                unplanned depreciation in the custom table xx_fa_unp_deprn_stg|
-- | Parameters  :  errbuf,retcode,process_mode,book_type,p_batch_id    |
-- +====================================================================+

PROCEDURE fa_unplanned_depreciation( x_errbuf      	OUT NOCOPY VARCHAR2
                       ,x_retcode     	OUT NOCOPY VARCHAR2                      
                       ,p_process_mode 	IN  VARCHAR2
		             ,p_book_type	IN  VARCHAR2                   	
				  ,p_batch_id IN NUMBER
  		      )            
IS

CURSOR C1(p_batch_id NUMBER)
IS
SELECT *
  FROM xx_fa_unp_deprn_stg
 WHERE process_flag+0=4
   AND book_type_code=p_book_type
   AND process_mode='RUN'
   AND error_flag = 'N'
   AND batch_id=p_batch_id;

CURSOR c_get_context_date
IS
SELECT greatest(calendar_period_open_date,
       least(sysdate, calendar_period_close_date)),
       calendar_period_close_date
  FROM fa_deprn_periods
 WHERE book_type_code = p_book_type
   AND period_close_date IS NULL;

    l_errbuf        VARCHAR2(4000);
    l_retcode       NUMBER := 0;
   
    ln_chart_of_accounts_id         NUMBER;
    ln_cntr NUMBER:=0;

BEGIN
  
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Process Mode  :   '||p_process_mode);
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Book Type     :   '||p_book_type);     

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
                                                                         
   UPDATE xx_fa_unp_deprn_stg a
      SET error_flag='Y'
         ,process_flag = 3
         ,error_message=error_message||'Asset_Number is Invalid'
    WHERE a.process_flag+0 = 1
      AND a.process_mode='PREVIEW'
      AND a.batch_id = p_batch_id
      AND NOT EXISTS (SELECT 'x'
	      		  FROM fa_books
    		            WHERE asset_id=a.asset_id
    			         AND book_type_code=a.book_type_code);                            

   FND_FILE.PUT_LINE(FND_FILE.LOG,'Asset is invalid for '||SQL%ROWCOUNT||' records');
   COMMIT;
      
   UPDATE xx_fa_unp_deprn_stg a
      SET error_flag='Y'
         ,process_flag = 3
         ,error_message=error_message||'Book Type Code is Invalid'
    WHERE a.process_flag+0 = 1
      AND a.process_mode='PREVIEW'
      AND a.batch_id = p_batch_id
      AND NOT EXISTS (SELECT 'x'
    		             FROM FA_BOOK_CONTROLS_SEC b
                       WHERE nvl(b.date_ineffective,sysdate+1) > sysdate
    		              AND b.book_type_code=a.book_type_code);

   FND_FILE.PUT_LINE(FND_FILE.LOG,'Book Type Code is invalid for '||SQL%ROWCOUNT||' records');
   COMMIT;
            
   UPDATE xx_fa_unp_deprn_stg xfuds
      SET UNP_TYPE_CODE = (SELECT lookup_code
         		             FROM fa_lookups 
                            WHERE lookup_type = 'UNPLANNED DEPRN'
                              AND UPPER(meaning) = UPPER(xfuds.UNP_TYPE)
		                )
    WHERE process_flag+0 = 1
      AND unp_type IS NOT NULL
      AND batch_id = p_batch_id;
   COMMIT;
                      
   UPDATE xx_fa_unp_deprn_stg
      SET process_Flag = 3
         ,error_flag = 'Y'
         , error_message=error_message||'Unplanned Type value is Invalid'
    WHERE process_flag+0 = 1
      AND batch_id = p_batch_id
      AND unp_type_code IS NULL
      AND unp_type IS NOT NULL;
                      
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Unplanned Type Value is invalid for '||SQL%ROWCOUNT||' records');
   COMMIT;              
      
   BEGIN
     SELECT chart_of_accounts_id  
       INTO ln_chart_of_accounts_id
       FROM gl_ledgers 
      WHERE ledger_id = (SELECT set_of_books_id 
                           FROM fa_book_controls
                          WHERE book_type_code = p_book_type);  
   EXCEPTION
     WHEN OTHERS THEN
       l_retcode := 2;
       l_errbuf  := 'Deriving Chart of Accounts ID is failed';
   END;
      
   UPDATE xx_fa_unp_deprn_stg xfuds
      SET xfuds.UNP_DEPR_CCID = (FND_FLEX_EXT.get_ccid(application_short_name  => 'SQLGL'
                                                        ,key_flex_code           => 'GL#'
                                                        ,structure_number        => ln_chart_of_accounts_id
                                                        ,validation_date         => NULL
                                                        ,concatenated_segments   => xfuds.UNP_DEPR_CC
                                                        )
                      )
    WHERE process_flag+0 = 1
      AND unp_depr_cc IS NOT NULL
      AND batch_id=p_batch_id;
          
   UPDATE  xx_fa_unp_deprn_stg
      SET  unp_depr_ccid = NULL
          ,process_flag = 3
          ,error_flag = 'Y'
          ,error_message= error_message||','||'Code Combination is Invalid'           
    WHERE process_flag+0 = 1
      AND unp_depr_cc IS NOT NULL
      AND unp_depr_ccid = 0
      AND batch_id=p_batch_id;
           
          
   IF (p_process_mode='RUN') THEN
  
       FOR cur IN c1(p_batch_id) LOOP

         ln_cntr := ln_cntr + 1;
         IF ln_cntr >= 5000 THEN
            COMMIT;
            ln_cntr := 0;
         END IF; 

         xx_fa_unplan_depr_api(
				          cur.asset_id
				         ,cur.book_type_code
                              ,cur.unp_depr_ccid
                              ,cur.unp_amount
                              ,cur.unp_type_code
                              ,p_batch_id
	                        );        
       END LOOP;
      
   END IF;  -- (p_process_mode='RUN') THEN
      
   IF p_process_mode = 'PREVIEW' THEN

      UPDATE xx_fa_unp_deprn_stg 
         SET process_Flag = 4
       WHERE batch_id=p_batch_id
         AND process_mode = 'PREVIEW'
         AND process_flag+0 = 1;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Updated '||SQL%ROWCOUNT||' records with process_flag = 4 for the success records in PREVIEW Mode');     
   ELSE

      UPDATE xx_fa_unp_deprn_stg 
         SET process_Flag = 7
       WHERE batch_id=p_batch_id
          AND process_mode = 'RUN'
          AND process_flag+0 = 4; 
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Updated '||SQL%ROWCOUNT||' records with process_flag = 7 for the success records in RUN Mode');     
   END IF;        
   COMMIT;
  
  x_errbuf  :=  l_errbuf;
  x_retcode :=  l_retcode;
 
EXCEPTION
  WHEN others THEN 
    x_errbuf:= ' When others Exception - '||SQLCODE||' - '||SUBSTR (SQLERRM,1,3500);
    x_retcode:=2;      
END fa_unplanned_depreciation;

-- +====================================================================+
-- | Name        :  bat_child                                           |
-- | Description :  This procedure is invoked from the 			   |
-- |                master_main procedure to submit the child program   | 
-- |                OD: FA Mass Unplanned Depreciation Child Program    |
-- |                                                                    |
-- | Parameters  :  p_book_type                                         |
-- |                p_process_mode                                      |
-- |                                                                    |
-- | Returns     :  request_id                                          |
-- |                                                                    |
-- +====================================================================+

FUNCTION bat_child (  p_process_mode 	  IN VARCHAR2
			     ,p_book_type IN VARCHAR2
		   )
RETURN NUMBER
IS
 ln_seq              	NUMBER;
 ln_rec_count		NUMBER;
 ln_crequest_id		NUMBER;
 ex_sequence            EXCEPTION;
BEGIN
   --FND_FILE.PUT_LINE(FND_FILE.LOG,'Begin function bat_child');
   BEGIN
     SELECT XX_FA_MADJ_STG_S.NEXTVAL
       INTO ln_seq
       FROM DUAL;
   EXCEPTION
     WHEN others THEN
       ln_seq:=-1;
       RAISE ex_sequence;
   END;
   
   --FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_seq - '||ln_seq);
   
   IF p_process_mode='PREVIEW' THEN
      UPDATE xx_fa_unp_deprn_stg
         SET batch_id=ln_seq
       WHERE process_flag = 1
         AND book_type_code=p_book_type
         AND batch_id IS NULL
         AND rownum<=gn_batch_size;
         
      ln_rec_count:=SQL%ROWCOUNT;
      COMMIT;
      
   ELSE
      UPDATE xx_fa_unp_deprn_stg
         SET batch_id=ln_seq
       WHERE process_flag = 4
         AND book_type_code=p_book_type
         AND batch_id IS NULL
         AND rownum<=gn_batch_size;
         
      ln_rec_count:=SQL%ROWCOUNT;
      
      COMMIT; 
      
   END IF;

   ln_crequest_id := 0;
   IF ln_rec_count > 0  THEN
          ln_crequest_id := FND_REQUEST.submit_request(
                                                        application =>  'XXFIN'
                                                       ,program     =>  'XXFAMAUP'
                                                       ,sub_request =>  TRUE
                                                       ,argument1   =>  p_process_mode
                                                       ,argument2   =>  p_book_type
                                                       ,argument3   =>  ln_seq
                                                       );
        IF ln_crequest_id = 0 THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG , 'Error while submitting OD: FA Mass Unplanned Depreciation Child Program');
        ELSE
           COMMIT;
	      RETURN(ln_crequest_id);
        END IF;
   END IF;  --IF ln_rec_count > 0  THEN
EXCEPTION
  WHEN ex_sequence THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG , 'XX_FA_MADJ_STG_S does not exists');
    RETURN(-1);
  WHEN others THEN
    RETURN(-1);   
    FND_FILE.PUT_LINE(FND_FILE.LOG , 'Error in bat_child '||SQLERRM);
END bat_child;
-- +====================================================================+
-- | Name        :  master_main                                         |
-- | Description :  This procedure is invoked from the 			   |
-- |                OD: FA Mass Unplanned Depreciation Process.         | 
-- |                This would submit child programs based on batch_size|
-- |                                                                    |
-- | Parameters  :  p_book_type                                         |
-- |                p_process_mode                                      |
-- |                                                                    |
-- | Returns     :  x_errbuf                                            |
-- |                x_retcode                                           |
-- |                                                                    |
-- +====================================================================+
PROCEDURE master_main(
                      x_errbuf              OUT NOCOPY VARCHAR2
                     ,x_retcode             OUT NOCOPY VARCHAR2
                     ,p_process_mode		  IN        VARCHAR2
          		     ,p_book_type            IN        VARCHAR2            		     
                     )
IS
--==============================================================================
-- Cursor Declarations to get the records which alreay previewed
--==============================================================================
  CURSOR c_check_preview(c_request_id NUMBER,c_book_type VARCHAR2)
  IS
  SELECT a.asset_id, a.request_id
    FROM xx_fa_unp_deprn_stg a
   WHERE a.process_mode='PREVIEW'
     AND a.process_flag=1
     AND a.request_id=c_request_id
     AND a.book_type_code=c_book_type
     AND EXISTS (SELECT 'x'
      		   FROM xx_fa_unp_deprn_stg b
       		  WHERE b.asset_id=a.asset_id            
      		    AND b.process_mode=a.process_mode
      		    AND b.book_type_code=a.book_type_code
      		    AND b.process_Flag+0=4);
               
 ln_current_count	NUMBER:=0;
 ln_run_count	   	NUMBER:=0;
 ln_seq              	NUMBER;
 ln_rec_count		NUMBER;
 ln_tot_count		NUMBER;
 ln_crequest_id		NUMBER;
 ln_tot_batches  NUMBER;
 lp_cnt          NUMBER;
 i 			NUMBER := 1;
 req_data 		VARCHAR2(240) := NULL;
 l_prv_complete		VARCHAR2(1);
 ln_request_id		NUMBER := fnd_global.conc_request_id;
 ln_eligible_rec_cnt  NUMBER;
 ln_preview_latest_req_id NUMBER;
 lc_child_req     VARCHAR2(1);
 
BEGIN

  FND_FILE.PUT_LINE(FND_FILE.LOG,'Process Mode  :   '||p_process_mode);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Book Type     :   '||p_book_type);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'');
  
  req_data := fnd_conc_global.request_data;
  IF (req_data IS NULL) THEN
     --FND_FILE.PUT_LINE(FND_FILE.LOG ,'Request Data is null');
     BEGIN
       SELECT  TV.target_value1
              ,TV.target_value2
         INTO  gn_batch_size,gn_threads
         FROM  XX_FIN_TRANSLATEVALUES TV
              ,XX_FIN_TRANSLATEDEFINITION TD
        WHERE  TV.TRANSLATE_ID  = TD.TRANSLATE_ID
          AND  TRANSLATION_NAME = 'XX_FA_MASS_ADJUSTMENTS';  
     EXCEPTION
       WHEN others THEN
        gn_batch_size:=25000;
        gn_threads:=5;
     END;
     -- Validations begin
     IF p_process_mode='RUN' THEN
        l_prv_complete := 'Y';
        BEGIN
          SELECT 'N'
            INTO l_prv_complete
            FROM DUAL
            WHERE EXISTS (SELECT 'x'
  	 	                 FROM xx_fa_unp_deprn_stg
   		                WHERE process_Flag = 1
                             AND book_type_code = p_book_type
         	         );
        EXCEPTION
          WHEN others THEN
  	    l_prv_complete:=NULL;
        END;
        --FND_FILE.PUT_LINE(FND_FILE.LOG,'l_prv_complete - '||l_prv_complete);
        IF l_prv_complete='N'  THEN
           x_errbuf :='Preview not completed for all Assets of book type '||p_book_type||'. Please execute this program with PREVIEW mode for this book type.';
           x_retcode  := 2;  
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Validation Error - '||x_errbuf);
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Validation Error - '||x_errbuf);         
           RETURN;
        END IF;
     END IF;   -- IF p_process_mode='RUN' THEN 
        
     -- Purge records of status 7 or 3 or 6 and aged older than 30 days
     purge_proc;
     
     FND_FILE.PUT_LINE(FND_FILE.LOG ,'Records purged which are older than 30 days with process flag 3,6 and 7');
     
     ln_eligible_rec_cnt := 0;
     
     IF  p_process_mode = 'PREVIEW' THEN
         SELECT COUNT(1)  
           INTO ln_eligible_rec_cnt
           FROM xx_fa_unp_deprn_stg
          WHERE process_flag = 1 
            AND request_id = -1                
            AND book_type_code = p_book_type;
     ELSE
       SELECT COUNT(1)  
         INTO ln_eligible_rec_cnt
         FROM xx_fa_unp_deprn_stg
        WHERE process_flag = 4 
          AND request_id <> ln_request_id
          AND book_type_code = p_book_type;         
     END IF;

     --FND_FILE.PUT_LINE(FND_FILE.LOG ,'Eligible record count '||ln_eligible_rec_cnt);
     
     IF ln_eligible_rec_cnt = 0 THEN
        x_errbuf := 'No Eligible records to process for this program';
        x_retcode := 1;
        FND_FILE.PUT_LINE(FND_FILE.LOG ,'No Eligible records to process for this program');
        RETURN;     
     ELSE
        ln_tot_batches := CEIL(ln_eligible_rec_cnt/25000);
        --FND_FILE.PUT_LINE(FND_FILE.LOG ,'Total batches '||ln_tot_batches);
        lp_cnt := 0;
        ln_preview_latest_req_id := 0;
        IF p_process_mode = 'RUN' THEN
           SELECT max(request_id)
             INTO ln_preview_latest_req_id
             FROM xx_fa_unp_deprn_stg
            WHERE process_Flag = 4
              AND book_type_code = p_book_type
              AND process_mode = 'PREVIEW';
        END IF;
        WHILE (lp_cnt < ln_tot_batches)  
        LOOP
          lp_cnt := lp_cnt + 1;
          IF  p_process_mode = 'PREVIEW' THEN
              UPDATE xx_fa_unp_deprn_stg
                 SET request_id = ln_request_id,
		          process_mode=p_process_mode
               WHERE process_Flag = 1
                 AND book_type_code = p_book_type
                 AND request_id = -1
                 AND rownum <= 25000;
              COMMIT;              
            
          ELSIF p_process_mode = 'RUN' THEN
              UPDATE xx_fa_unp_deprn_stg
                 SET request_id = ln_request_id,
	                process_mode=p_process_mode,
		           batch_id=null  	 
              WHERE process_Flag = 4
                AND book_type_code = p_book_type
                AND request_id = ln_preview_latest_req_id  -- Consider only the latest previewed records
                AND rownum <= 25000; 
              COMMIT;           
          END IF;      -- END IF of IF  p_process_mode = 'PREVIEW' THEN
        END LOOP;
        
        -- For pending records which are not updated in above loop
        IF p_process_mode = 'PREVIEW' THEN
        
           UPDATE xx_fa_unp_deprn_stg
              SET request_id = ln_request_id,
		       process_mode=p_process_mode
            WHERE process_Flag = 1
              AND book_type_code = p_book_type
              AND request_id = -1;
           COMMIT;
              
        ELSIF p_process_mode = 'RUN' THEN
        
          UPDATE xx_fa_unp_deprn_stg
             SET request_id = ln_request_id,
		      process_mode=p_process_mode,
   	            batch_id=null  	
           WHERE process_Flag = 4
             AND book_type_code = p_book_type
             AND request_id = ln_preview_latest_req_id;  -- Consider only the latest previewed records
          COMMIT;           
        END IF;   -- END IF of IF  p_process_mode = 'PREVIEW' THEN      
     END IF;       -- END IF of IF ln_eligible_rec_cnt = 0 THEN
     
     UPDATE xx_fa_unp_deprn_stg
        SET process_Flag = 3
           ,error_flag = 'Y'
           ,error_message = 'Asset_id is NULL or book_type_code is NULL'
      WHERE process_flag = 1
        AND request_id = ln_request_id
        AND (asset_id IS NULL or book_type_code IS NULL);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Updated '||SQL%ROWCOUNT||' records for  asset_number/book_type_code is NULL');
      COMMIT;
      --FND_FILE.PUT_LINE(FND_FILE.LOG,'Checking the already existed PREVIEWED records');
      FOR cur IN c_check_preview(ln_request_id, p_book_type) LOOP
        UPDATE xx_fa_unp_deprn_stg
           set process_flag = 7
         WHERE asset_id=cur.asset_id
           AND process_Flag+0 = 4
           AND process_mode='PREVIEW'
           AND book_type_code=p_book_type;           
      END LOOP;
      COMMIT; 
         
      --FND_FILE.PUT_LINE(FND_FILE.LOG,'Checking the duplicate assets');
      UPDATE  xx_fa_unp_deprn_stg mxfuds
         SET  mxfuds.PROCESS_FLAG = 3
            , mxfuds.ERROR_FLAG = 'Y'
            , mxfuds.ERROR_MESSAGE = ERROR_MESSAGE||':'||'Duplicate Asset_id'
       WHERE mxfuds.process_flag = 1
         AND mxfuds.request_id = ln_request_id
         AND mxfuds.asset_id in (SELECT cxfuds.asset_id
                                   FROM xx_fa_unp_deprn_stg cxfuds
                                  WHERE process_flag+0=1
                                    AND request_id=ln_request_id
                                  GROUP BY cxfuds.asset_id
                                  HAVING COUNT(1) > 1
                            );   
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Updated '||SQL%ROWCOUNT||' records with Error as the asset_id is duplicate'); 
      COMMIT;
      -- Validations End
      --FND_FILE.PUT_LINE(FND_FILE.LOG,'End of Validations');
     lc_child_req := 'N';
     LOOP
      
       --FND_FILE.PUT_LINE(FND_FILE.LOG,'Inside Loop for Child');
       SELECT COUNT(1)
         INTO ln_run_count
         FROM fnd_concurrent_requests
        WHERE concurrent_program_id IN (SELECT concurrent_program_id
				       FROM fnd_concurrent_programs
				      WHERE concurrent_program_name='XXFAMAUP'
				        AND application_id=20043
				        AND enabled_flag='Y')
          AND program_application_id=20043
          AND phase_code IN ('P','R');
       
       --FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_run_count '||ln_run_count);
       --FND_FILE.PUT_LINE(FND_FILE.LOG,'gn_threads '||gn_threads);
          
       IF ln_run_count=gn_threads THEN
          --FND_FILE.PUT_LINE(FND_FILE.LOG ,'Request Data is null, about to exit in gnthreads :'||TO_CHAR(gn_threads));
          EXIT;
       END IF;
       
       IF p_process_mode='PREVIEW' THEN
          SELECT COUNT(1)
            INTO ln_current_count
            FROM xx_fa_unp_deprn_stg
           WHERE process_flag = 1
             AND book_type_code=p_book_type
             AND batch_id IS NULL
	        AND ROWNUM<2;
       ELSE
          SELECT COUNT(1)
            INTO ln_current_count
            FROM xx_fa_unp_deprn_stg
           WHERE process_flag = 4
             AND book_type_code=p_book_type
             AND batch_id IS NULL
	        AND ROWNUM<2;
       END IF;
       --FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_current_count '||ln_current_count);
       
       IF ln_current_count = 0 THEN      -- No records eligible to do the process
           EXIT;
       ELSE
        --FND_FILE.PUT_LINE(FND_FILE.LOG,'Invoking bat_child');
    	  ln_crequest_id:=bat_child(p_process_mode,p_book_type);
        --FND_FILE.PUT_LINE(FND_FILE.LOG , 'ln_crequest_id - '||ln_crequest_id);
        IF ln_crequest_id > 0 THEN          
          lc_child_req := 'Y';
          --FND_FILE.PUT_LINE(FND_FILE.LOG , 'After setting, the  lc_child_req is '||lc_child_req);
        END IF;
    	  FND_FILE.PUT_LINE(FND_FILE.LOG , 'Submitted the child program to process records, request_id : '||TO_CHAR(ln_crequest_id));
       END IF;
     END LOOP;
     
     --FND_FILE.PUT_LINE(FND_FILE.LOG , 'ln_current_count is '||ln_current_count);
     --FND_FILE.PUT_LINE(FND_FILE.LOG , 'lc_child_req is '||lc_child_req);
     
     IF ln_current_count = 0 and lc_child_req = 'N' THEN
	   FND_FILE.PUT_LINE(FND_FILE.LOG , 'No Eligible records to process for this program');  
        display_output(ln_request_id, p_process_mode);
        x_errbuf := 'No Eligible records to process for this program';
        x_retcode := 1;
        RETURN;
     END IF;
    
     --FND_FILE.PUT_LINE(FND_FILE.LOG , 'lc_child_req is '||lc_child_req);
     IF lc_child_req = 'Y' THEN
        FND_CONC_GLOBAL.SET_REQ_GLOBALS(conc_status => 'PAUSED',request_data =>TO_CHAR(i));
     END IF;
     
  ELSE     ---IF (req_data IS NOT NULL) THEN
     i := to_number(req_data);
     i := i + 1;
     --FND_FILE.PUT_LINE(FND_FILE.LOG ,'Else of Request data');
     BEGIN
       SELECT  TV.target_value1
              ,TV.target_value2
         INTO  gn_batch_size,gn_threads
         FROM  XX_FIN_TRANSLATEVALUES TV
              ,XX_FIN_TRANSLATEDEFINITION TD
        WHERE TV.TRANSLATE_ID  = TD.TRANSLATE_ID
          AND TRANSLATION_NAME = 'XX_FA_MASS_ADJUSTMENTS';  
     EXCEPTION
       WHEN others THEN
        gn_batch_size:=10000;
        gn_threads:=5;
     END;
     --FND_FILE.PUT_LINE(FND_FILE.LOG ,'GN Threads : '||to_char(gn_threads));
     LOOP
       SELECT COUNT(1)
         INTO ln_run_count
         FROM fnd_concurrent_requests
        WHERE concurrent_program_id IN (SELECT concurrent_program_id
				       FROM fnd_concurrent_programs
				      WHERE concurrent_program_name='XXFAMAUP'
				        AND application_id=20043
				        AND enabled_flag='Y')
          AND program_application_id=20043
          AND phase_code IN ('P','R');
      
       --FND_FILE.PUT_LINE(FND_FILE.LOG , 'Else part check count '||ln_run_count);
       
       IF ln_run_count=gn_threads THEN
          EXIT;
       END IF;
       IF p_process_mode='PREVIEW' THEN
          SELECT COUNT(1)
            INTO ln_current_count
            FROM xx_fa_unp_deprn_stg
           WHERE process_flag = 1
             AND book_type_code=p_book_type
             AND batch_id IS NULL
	     AND ROWNUM<2;
       ELSE
          SELECT COUNT(1)
            INTO ln_current_count
            FROM xx_fa_unp_deprn_stg
           WHERE process_flag = 4
             AND book_type_code=p_book_type
             AND batch_id IS NULL
	     AND ROWNUM<2;
       END IF;
       
       --FND_FILE.PUT_LINE(FND_FILE.LOG , 'In Else part , ln_current_count- '||ln_current_count);
       
       IF ln_current_count=0 THEN
           EXIT;
       ELSE
      	  ln_crequest_id:=bat_child(p_process_mode,p_book_type);
      	  FND_FILE.PUT_LINE(FND_FILE.LOG , 'Submitted the child program to process records, request_id : '||TO_CHAR(ln_crequest_id));
       END IF;
     END LOOP;
     
     SELECT COUNT(1)
       INTO ln_tot_count
       FROM fnd_concurrent_requests
      WHERE concurrent_program_id IN (SELECT concurrent_program_id
				       FROM fnd_concurrent_programs
				      WHERE concurrent_program_name='XXFAMAUP'
				        AND application_id=20043
				        AND enabled_flag='Y')
        AND program_application_id=20043
        AND phase_code IN ('P','R'); 
        
     IF p_process_mode='PREVIEW' THEN
          SELECT COUNT(1)
            INTO ln_current_count
            FROM xx_fa_unp_deprn_stg
           WHERE process_flag = 1
             AND book_type_code=p_book_type
             AND batch_id IS NULL
	     AND ROWNUM<2;
     ELSE
          SELECT COUNT(1)
            INTO ln_current_count
            FROM xx_fa_unp_deprn_stg
           WHERE process_flag = 4
             AND book_type_code=p_book_type
             AND batch_id IS NULL
	     AND ROWNUM<2;
     END IF;
     
     --FND_FILE.PUT_LINE(FND_FILE.LOG , 'To display output, ln_tot_count is '||ln_tot_count);
     --FND_FILE.PUT_LINE(FND_FILE.LOG , 'To display output, ln_current_count is '||ln_current_count);
     
     IF (ln_tot_count=0) AND (ln_current_count=0) THEN
        display_output(ln_request_id, p_process_mode);
        x_errbuf :=NULL;
        x_retcode:=0;
        RETURN;
     END IF;
     fnd_conc_global.set_req_globals(conc_status => 'PAUSED',request_data =>TO_CHAR(i));
  END IF;  --  IF (req_data IS NULL) THEN
EXCEPTION
WHEN OTHERS THEN
   x_retcode := 2;
   x_errbuf  := 'Unexpected error in master_main procedure - '||SQLERRM;
END master_main;

END XX_FA_MASS_UNP_DEPRN_PKG;
/
SHOW ERRORS;
