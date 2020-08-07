-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- +===========================================================================+
-- | Name        :    XX_C2T_CC_DEPOSITS_PREP_PHASE_4_1.sql                    |
-- | Description :    Populate XX_C2T_PREP_THREADS_DEPOSITS Table for          |
-- |                  Pre-Processing Phase                                     |
-- | Rice ID     :    C0705                                                    |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date         Author                Remarks                        |
-- |=======  ===========  ==================    ===============================|
-- | 1.0     09-24-2015   Havish Kasina         Initial Version                |
-- +===========================================================================+
 DECLARE
 lc_location      VARCHAR2(500);
 gn_user_id      fnd_concurrent_requests.requested_by%TYPE   := FND_GLOBAL.USER_ID;
 gn_login_id     fnd_concurrent_requests.conc_login_id%TYPE  := FND_GLOBAL.LOGIN_ID;
 BEGIN

    lc_location := 'TRUNCATE TABLE XX_C2T_PREP_THREADS_DEPOSITS ';
    DBMS_OUTPUT.PUT_LINE( lc_location );
    EXECUTE IMMEDIATE 'TRUNCATE TABLE XXOM.XX_C2T_PREP_THREADS_DEPOSITS';
			
    lc_location := 'INSERTING Values in table XX_C2T_PREP_THREADS_DEPOSITS';
    DBMS_OUTPUT.PUT_LINE( lc_location );			
    INSERT INTO XX_C2T_PREP_THREADS_DEPOSITS (
                                             min_deposit_id
                                          ,  max_deposit_id
                                          ,  thread_num
                                          ,  total_count
                                          ,  creation_date
                                          ,  last_update_date
                                          ,  last_deposit_id
                                          )	
                SELECT MIN(X.deposit_id)      min_deposit_id
                     , MAX(X.deposit_id)      max_deposit_id
                     , X.thread_num           thread_num
                     , COUNT(1)               total_count                     
                     , SYSDATE                creation_date
                     , SYSDATE                last_update_date
                     , MIN(X.deposit_id)      last_deposit_id
                 FROM (SELECT /*+ parallel(DEP) full(DEP) */ 
                              DEP.deposit_id
                            , NTILE(10) OVER(ORDER BY DEP.deposit_id) thread_num
                       FROM xx_c2t_cc_token_stg_deposits DEP) X
                GROUP BY X.thread_num
                ORDER BY X.thread_num;
    COMMIT;
    			
 EXCEPTION
 WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE( 'ENCOUNTERED ERROR WHILE :: '||lc_location);
    DBMS_OUTPUT.PUT_LINE( 'ERROR MESSAGE :: '||SQLERRM);
 END;
/