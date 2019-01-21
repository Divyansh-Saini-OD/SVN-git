	-- +===========================================================================+
	-- |                  Office Depot - Project Simplify                          |
	-- +===========================================================================+
	-- | Name        : XX_C2T_CC_ORDT_STG_PHASE_3_1.sql                            |
	-- | Description : Script to insert data in Threading data in  XX_C2T_CONV_THREADS_IBY_HIST |
	-- |                                                                           |
	-- |Change Record:                                                             |
	-- |===============                                                            |
	-- |Version  Date         Author                Remarks                        |
	-- |=======  ===========  ==================    ===============================|
	-- |v1.0     13-OCT-2015  Harvinder Rakhra      Initial version                |  
	-- |v1.1     21-OCT-2015  Harvinder Rakhra      Alter session commands modified| 
	-- +===========================================================================+
 DECLARE
 l_location      VARCHAR2(500);
 gn_user_id      fnd_concurrent_requests.requested_by%TYPE   := NVL ( FND_GLOBAL.USER_ID, -1);
 gn_login_id     fnd_concurrent_requests.conc_login_id%TYPE  := NVL ( FND_GLOBAL.LOGIN_ID , -1);
 BEGIN

    l_location := 'TRUNCATE  TABLE XXFIN.XX_C2T_CONV_THREADS_IBY_HIST ';
    DBMS_OUTPUT.PUT_LINE( l_location );
    EXECUTE IMMEDIATE 'TRUNCATE  TABLE XXFIN.XX_C2T_CONV_THREADS_IBY_HIST';
	
    EXECUTE IMMEDIATE 'ALTER SESSION ENABLE PARALLEL DML';
			
    l_location := 'INSERTING Values in table XX_C2T_CONV_THREADS_IBY_HIST';
    DBMS_OUTPUT.PUT_LINE( l_location );			
    INSERT INTO xx_c2t_conv_threads_iby_hist (
                                           min_hist_id
                                         , max_hist_id
                                         , total_cnt
                                         , thread_num
                                         , creation_date
                                         , last_update_date
                                         )	
                SELECT MIN(X.hist_id)            min_hist_id
                     , MAX(X.hist_id)            max_hist_id
                     , COUNT(1)                  total_cnt
                     , X.thread_num              thread_num
                     , SYSDATE                   creation_date
                     , SYSDATE                   last_update_date
                 FROM (SELECT /*+ parallel(IBY_HIST) full(IBY_HIST) */ 
                              IBY_HIST.hist_id
                            , NTILE(1000) OVER(ORDER BY IBY_HIST.hist_id) thread_num
                       FROM xx_c2t_cc_token_stg_iby_hist IBY_HIST) X
                GROUP BY X.thread_num
                ORDER BY X.thread_num;

			
    EXECUTE IMMEDIATE 'ALTER TABLE XXFIN.XX_C2T_CONV_THREADS_IBY_HIST noparallel';
			
 EXCEPTION
 WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE( 'ENCOUNTERED ERROR WHILE :: '||l_location);
    DBMS_OUTPUT.PUT_LINE( 'ERROR MESSAGE :: '||SQLERRM);
 END;
/
