DECLARE

-- +===========================================================================+
-- |                            Office Depot Inc.                              |
-- +===========================================================================+
-- | Name        :    XX_C2T_CC_RETURNS_CONVERT_PHASE_5_1.sql                  |
-- | Description :    Populate XX_C2T_CONV_THREADS_RETS Table for Convert Phase|
-- | Rice Id     :    C0705                                                    |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date         Author                Remarks                        |
-- |=======  ===========  ==================    ===============================|
-- | 1.0     09-27-2015   Manikant Kasu         Initial Version                |
-- +===========================================================================+

 lc_location      VARCHAR2(500);
 gn_user_id      fnd_concurrent_requests.requested_by%TYPE   := FND_GLOBAL.USER_ID;
 gn_login_id     fnd_concurrent_requests.conc_login_id%TYPE  := FND_GLOBAL.LOGIN_ID;

 BEGIN

    lc_location := 'TRUNCATE  TABLE XXOM.XX_C2T_CONV_THREADS_RETURNS ';
    DBMS_OUTPUT.PUT_LINE( lc_location );
    EXECUTE IMMEDIATE 'TRUNCATE TABLE XXOM.XX_C2T_CONV_THREADS_RETURNS';
			
    lc_location := 'INSERTING Values in table XX_C2T_CONV_THREADS_RETURNS';
    DBMS_OUTPUT.PUT_LINE( lc_location );			
    INSERT INTO XX_C2T_CONV_THREADS_RETURNS (
                                             min_return_id
                                          ,  max_return_id
                                          ,  thread_num
                                          ,  total_count
                                          ,  creation_date
                                          ,  last_update_date
                                          )	
                SELECT MIN(X.return_id)          min_return_id
                     , MAX(X.return_id)          max_return_id
                     , X.thread_num              thread_num
                     , COUNT(1)                  total_count                     
                     , SYSDATE                   creation_date
                     , SYSDATE                   last_update_date
                 FROM (SELECT /*+ parallel(RETS) full(RETS) */ 
                              RETS.return_id
                            , NTILE(128) OVER(ORDER BY RETS.return_id) thread_num
                       FROM xx_c2t_cc_token_stg_returns RETS) X
                GROUP BY X.thread_num
                ORDER BY X.thread_num;

    COMMIT;
  		
 EXCEPTION
 WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE( 'ENCOUNTERED ERROR WHILE :: '||lc_location);
    DBMS_OUTPUT.PUT_LINE( 'ERROR MESSAGE :: '||SQLERRM);
 END;
/