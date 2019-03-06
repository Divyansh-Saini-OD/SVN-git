DECLARE
-- +===================================================================+
-- |                        Office Depot Inc.                          |
-- +===================================================================+
-- | Script Name :  XX_C2T_CC_RETURNS_PREP_PHASE_4_1.sql               |
-- | Description :  Script to insert records into preprocessing threads|
-- |                table for Returns                                  |
-- | Rice Id     :  C0705                                              |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author             Remarks                  |
-- |=======   ===========  =================  =========================|
-- |1.0       16-Sep-2015  Manikant Kasu      Initial draft version    |
-- +===================================================================+
 
 lc_location      VARCHAR2(500);
 gn_user_id      fnd_concurrent_requests.requested_by%TYPE   := FND_GLOBAL.USER_ID;
 gn_login_id     fnd_concurrent_requests.conc_login_id%TYPE  := FND_GLOBAL.LOGIN_ID;
 BEGIN

    lc_location := 'TRUNCATE  TABLE XXOM.XX_C2T_PREP_THREADS_RETURNS ';
    DBMS_OUTPUT.PUT_LINE( lc_location );
    EXECUTE IMMEDIATE 'TRUNCATE TABLE XXOM.XX_C2T_PREP_THREADS_RETURNS';
			
    lc_location := 'INSERTING Values in table XX_C2T_PREP_THREADS_RETURNS';
    DBMS_OUTPUT.PUT_LINE( lc_location );			
    INSERT INTO XX_C2T_PREP_THREADS_RETURNS (
                                             min_return_id
                                          ,  max_return_id
                                          ,  thread_num
                                          ,  total_count
                                          ,  creation_date
                                          ,  last_update_date
                                          ,  last_return_id
                                          )	
                SELECT MIN(X.return_id)       min_return_id
                     , MAX(X.return_id)       max_return_id
                     , X.thread_num           thread_num
                     , COUNT(1)               total_count                     
                     , SYSDATE                creation_date
                     , SYSDATE                last_update_date
                     , MIN(X.return_id)       last_return_id
                 FROM (SELECT /*+ parallel(XORT) full(XORT) */ 
                              XORT.return_id
                            , NTILE(10) OVER(ORDER BY XORT.return_id) thread_num
                       FROM xx_c2t_cc_token_stg_returns XORT) X
                GROUP BY X.thread_num
                ORDER BY X.thread_num;
    COMMIT;
						
 EXCEPTION
 WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE( 'ENCOUNTERED ERROR WHILE :: '||lc_location);
    DBMS_OUTPUT.PUT_LINE( 'ERROR MESSAGE :: '||SQLERRM);
 END;
/