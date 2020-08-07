-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- +===========================================================================+
-- | Name        :    XX_C2T_CC_OE_PMT_CONVERT_PHASE_5_1.sql                   |
-- | Description :    Populate XX_C2T_CONV_THREADS_OE_PMT Table for            |
-- |                  Convert Phase                                            |
-- | Rice ID     :    C0705                                                    |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date         Author                Remarks                        |
-- |=======  ===========  ==================    ===============================|
-- | 1.0     09-21-2015   Havish Kasina         Initial Version                |
-- +===========================================================================+
 DECLARE
 lc_location      VARCHAR2(500);
 gn_user_id      fnd_concurrent_requests.requested_by%TYPE   := FND_GLOBAL.USER_ID;
 gn_login_id     fnd_concurrent_requests.conc_login_id%TYPE  := FND_GLOBAL.LOGIN_ID;
 BEGIN

    lc_location := 'TRUNCATE  TABLE XX_C2T_CONV_THREADS_OE_PMT ';
    DBMS_OUTPUT.PUT_LINE( lc_location );
    EXECUTE IMMEDIATE 'TRUNCATE TABLE XXOM.XX_C2T_CONV_THREADS_OE_PMT';
			
    lc_location := 'INSERTING Values in table XX_C2T_CONV_THREADS_OE_PMT';
    DBMS_OUTPUT.PUT_LINE( lc_location );			
    INSERT INTO XX_C2T_CONV_THREADS_OE_PMT (
                                             min_oe_payment_id
                                          ,  max_oe_payment_id
                                          ,  thread_num
                                          ,  total_count
                                          ,  creation_date
                                          ,  last_update_date
                                          )	
                SELECT MIN(X.oe_payment_id)      min_oe_payment_id
                     , MAX(X.oe_payment_id)      max_oe_payment_id
                     , X.thread_num              thread_num
                     , COUNT(1)                  total_count                     
                     , SYSDATE                   creation_date
                     , SYSDATE                   last_update_date
                 FROM (SELECT /*+ parallel(OE_PMT) full(OE_PMT) */ 
                              OE_PMT.oe_payment_id
                            , NTILE(128) OVER(ORDER BY OE_PMT.oe_payment_id) thread_num
                       FROM xx_c2t_cc_token_stg_oe_pmt OE_PMT) X
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