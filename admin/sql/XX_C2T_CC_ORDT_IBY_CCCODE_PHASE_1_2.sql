	-- +===========================================================================+
	-- |                  Office Depot - Project Simplify                          |
	-- +===========================================================================+
	-- | Name        : XX_C2T_CC_ORDT_IBY_CCCODE_PHASE_1_2.sql                     |
	-- | Description : Script to insert data in ORDT Convertion Threading table    |
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

    l_location := 'TRUNCATE  TABLE XXFIN.XX_C2T_CONV_THREADS_ORDT ';
    DBMS_OUTPUT.PUT_LINE( l_location );
    EXECUTE IMMEDIATE 'TRUNCATE  TABLE XXFIN.XX_C2T_CONV_THREADS_ORDT';
	
    EXECUTE IMMEDIATE 'ALTER SESSION ENABLE PARALLEL DML';
			
    l_location := 'INSERTING Values in table XX_C2T_CONV_THREADS_ORDT';
    DBMS_OUTPUT.PUT_LINE( l_location );			
    INSERT INTO xx_c2t_conv_threads_ordt (
                                           min_order_payment_id
                                         , max_order_payment_id
                                         , total_cnt
                                         , thread_num
                                         , creation_date
                                         , last_update_date
                                         )	
                SELECT MIN(X.order_payment_id)   min_order_payment_id
                     , MAX(X.order_payment_id)   max_order_payment_id
                     , COUNT(1)                  total_cnt
                     , X.thread_num              thread_num
                     , SYSDATE                   creation_date
                     , SYSDATE                   last_update_date
                 FROM (SELECT /*+ parallel(ORDT) full(ORDT) */ 
                              ORDT.order_payment_id
                            , NTILE(1000) OVER(ORDER BY ORDT.order_payment_id) thread_num
                       FROM xx_c2t_cc_token_stg_ordt ORDT) X
                GROUP BY X.thread_num
                ORDER BY X.thread_num;

			
    EXECUTE IMMEDIATE 'ALTER TABLE XXFIN.XX_C2T_CONV_THREADS_ORDT NOPARALLEL';
			
 EXCEPTION
 WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE( 'ENCOUNTERED ERROR WHILE :: '||l_location);
    DBMS_OUTPUT.PUT_LINE( 'ERROR MESSAGE :: '||SQLERRM);
 END;
/
