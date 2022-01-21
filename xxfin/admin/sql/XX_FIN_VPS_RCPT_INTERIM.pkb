create or replace package body XX_FIN_VPS_RCPT_INTERIM
as
-- +==========================================================================================+
-- |                  Office Depot                                                            |
-- +==========================================================================================+
-- |Description : Populate receipts data into INTERIM table                                   | 
-- |                  XX_FIN_VPS_RCPT_INTERIM                                                 |
-- |                                                                                          |
-- |Change Record:                                                                            |
-- |===============                                                                           |
-- |Version      Date           Author                  Remarks                               |
-- |=======    ==========     =============             ======================                |
-- | 1.1       30-NOV-17      Thejaswini Rajula         Initial draft version                 |
-- | 1.2       07-JUN-18      Havish Kasina             Changes added as per Defect 25869     |
-- |                                                    (VPS Phase 2)                         |
-- +==========================================================================================+
g_pkg_name                                VARCHAR2(30):= 'XX_FIN_VPS_RCPT_INTERIM';

PROCEDURE GET_OA_RECEIPTS(ERRBUF                OUT  VARCHAR2
                          ,RETCODE               OUT  NUMBER
                          ,FROM_DATE             IN   VARCHAR2 DEFAULT NULL
                          ,TO_DATE               IN   VARCHAR2 DEFAULT NULL 
                          ) IS
                          
  lv_from_date                  DATE;
  lv_to_date                    DATE;
  lv_temp_from_date             DATE;
  lv_org_id                     hr_operating_units.organization_id%TYPE;
  lv_row_cnt                    NUMBER;
  lv_adj_row_cnt                NUMBER;
  lv_rcpt_row_cnt               NUMBER;
  
CURSOR cur_get_receipts (P_FROM_DATE DATE, P_TO_DATE DATE, p_org_id number)
IS 
SELECT /*+ leading(arra) ordered(ARAA,DEFN) index(ARAA,AR_RECEIVABLE_APPLICATIONS_N7) index(vals,XX_FIN_TRANSLATEVALUES_N1) */
                 rcta.customer_trx_id	      	
                ,acra.cash_receipt_id	      	
                ,araa.receivable_application_id
                ,araa.applied_customer_trx_id      	    
                ,acra.status RECEIPT_STATUS
                ,araa.status RECEV_APPL_STATUS
                ,acra.Receipt_number 
                ,acra.Receipt_date 
                ,araa.creation_date last_update_date 
                ,rcta.attribute14 AS VPS_Program_ID
                ,araa.amount_applied
            FROM  RA_CUSTOMER_TRX_ALL RCTA ,
                   AR_CASH_RECEIPTS_ALL ACRA ,
                   AR_RECEIVABLE_APPLICATIONS_ALL ARAA,
                   RA_CUST_TRX_TYPES_ALL          RCTT,
                   XX_FIN_TRANSLATEVALUES     VALS,
                   XX_FIN_TRANSLATEDEFINITION DEFN      
             WHERE RCTA.CUSTOMER_TRX_ID = ARAA.APPLIED_CUSTOMER_TRX_ID
             AND ACRA.CASH_RECEIPT_ID   = ARAA.CASH_RECEIPT_ID
             AND RCTA.CUST_TRX_TYPE_ID  = RCTT.CUST_TRX_TYPE_ID
             AND DEFN.TRANSLATE_ID      = VALS.TRANSLATE_ID
             AND DEFN.TRANSLATION_NAME  = 'OD_VPS_RECEIPT_TRX_TYPES'
             AND rcta.attribute14         is not null 
             AND ARAA.creation_date between (P_FROM_DATE) 
                                       and     (P_TO_DATE) 
             AND ARAA.status='APP'
             AND ACRA.org_id=p_org_id
             AND RCTT.NAME = VALS.SOURCE_VALUE1
             ORDER BY rcta.attribute14, acra.Receipt_number
        ;

/*+ Changes added as per Version 1.2 */		
CURSOR cur_get_adjustments (P_FROM_DATE DATE, P_TO_DATE DATE, p_org_id number)
IS 
SELECT  rcta.customer_trx_id	     	
       ,aaa.adjustment_id       	    	    
       ,aaa.status 
       ,aaa.adjustment_number 
       ,aaa.apply_date adjustment_date
       ,aaa.creation_date last_update_date
       ,rcta.attribute14 AS VPS_Program_ID
       ,aaa.amount 
  FROM RA_CUSTOMER_TRX_ALL RCTA ,
       AR_ADJUSTMENTS_ALL AAA,
       RA_CUST_TRX_TYPES_ALL     RCTT   
 WHERE RCTA.CUSTOMER_TRX_ID = AAA.CUSTOMER_TRX_ID
   AND RCTA.CUST_TRX_TYPE_ID  = RCTT.CUST_TRX_TYPE_ID
   AND rcta.attribute14         IS NOT NULL 
   AND AAA.creation_date BETWEEN (P_FROM_DATE) 
                              AND     (P_TO_DATE) 
   AND AAA.status = 'A'
   AND AAA.org_id = p_org_id
 ORDER BY rcta.attribute14,aaa.adjustment_number ;
        
cursor c_max_date
is
select max(RECEIPT_APPL_DATE)
from   XX_FIN_VPS_RECEIPTS_INTERIM;

BEGIN
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Begin+' );
    -- lv_from_date := FND_DATE.CANONICAL_TO_DATE (FROM_DATE);
      SELECT ORGANIZATION_ID
        INTO lv_org_id
        FROM HR_ALL_ORGANIZATION_UNITS
       WHERE NAME='OU_US_VPS'
       ;
       
      OPEN c_max_date;
      FETCH c_max_date into lv_temp_from_date;
      
      IF (FROM_DATE IS NULL) then
        lv_from_date := lv_temp_from_date;
      ELSE
        lv_from_date := FND_DATE.CANONICAL_TO_DATE (FROM_DATE);
      END IF;

      IF (TO_DATE IS NULL) then
        lv_to_date := SYSDATE;
       ELSE 
        lv_to_date := FND_DATE.CANONICAL_TO_DATE (TO_DATE);
      END IF;
       
      --MO_GLOBAL.SET_POLICY_CONTEXT('S',lv_org_id);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'FROM DATE: '||lv_from_date);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'TO DATE : '||lv_to_date);
  FOR i IN cur_get_receipts(lv_from_date, lv_to_date, lv_org_id) LOOP 
    BEGIN
        INSERT INTO  XX_FIN_VPS_RECEIPTS_INTERIM ( 
                    CUSTOMER_TRX_ID	      	,
                    CASH_RECEIPT_ID	      	,
                    RECEIVABLE_APPLICATION_ID,
                    APPLIED_CUSTOMER_TRX_ID,
                    RECEIPT_NUMBER,
                    RECEIPT_DATE,	      	
                    RECEIPT_APPL_DATE,	      
                    RECEIPT_STATUS,
                    RECEV_APPL_STATUS,
                    AMOUNT_APPLIED,
                    VPS_PROGRAM_ID,
                    INTERFACE_ID,
                    REQUEST_ID,
                    RECORD_STATUS,
                    VALIDATE_PROCESS_DATA,
                    LAST_UPDATE_DATE,         
                    LAST_UPDATED_BY,
                    CREATION_DATE,            
                    CREATED_BY
                   ) VALUES (
                    i.CUSTOMER_TRX_ID	      	,
                    i.CASH_RECEIPT_ID	      	,
                    i.RECEIVABLE_APPLICATION_ID,
                    i.APPLIED_CUSTOMER_TRX_ID,
                    i.RECEIPT_NUMBER,
                    i.RECEIPT_DATE,	      	
                    i.last_update_date,	      
                    i.RECEIPT_STATUS,
                    i.RECEV_APPL_STATUS,
                    i.AMOUNT_APPLIED,
                    i.VPS_Program_ID,
                    XX_FIN_VPS_RECEIPTS_INTERIM_S.nextval
                    ,fnd_global.conc_request_id
                    ,'I'
                    ,NULL
                    ,SYSDATE
                    ,FND_GLOBAL.USER_ID
                    ,SYSDATE
                    ,FND_GLOBAL.USER_ID
                   );    
      COMMIT;
      lv_rcpt_row_cnt := lv_rcpt_row_cnt + 1;
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Unique Index Violation :'||SQLERRM);
    END;
  END LOOP;
  /* Added as per Version 1.2 */
  FOR j IN cur_get_adjustments(lv_from_date, lv_to_date, lv_org_id) 
  LOOP 
    BEGIN
        INSERT INTO  XX_FIN_VPS_RECEIPTS_INTERIM ( 
                    CUSTOMER_TRX_ID	      	,
                    CASH_RECEIPT_ID	      	,
                    RECEIVABLE_APPLICATION_ID,
                    APPLIED_CUSTOMER_TRX_ID,
                    RECEIPT_NUMBER,
                    RECEIPT_DATE,	      	
                    RECEIPT_APPL_DATE,	      
                    RECEIPT_STATUS,
                    RECEV_APPL_STATUS,
                    AMOUNT_APPLIED,
                    VPS_PROGRAM_ID,
                    INTERFACE_ID,
                    REQUEST_ID,
                    RECORD_STATUS,
                    VALIDATE_PROCESS_DATA,
                    LAST_UPDATE_DATE,         
                    LAST_UPDATED_BY,
                    CREATION_DATE,            
                    CREATED_BY
                   ) VALUES (
                    j.CUSTOMER_TRX_ID ,
                    j.ADJUSTMENT_ID	,
                    NULL,
                    NULL,
                    j.ADJUSTMENT_NUMBER,
                    j.ADJUSTMENT_DATE,	      	
                    j.last_update_date,	      
                    j.STATUS,
                    NULL,
                    (-1) * j.amount,
                    j.VPS_Program_ID,
                    XX_FIN_VPS_RECEIPTS_INTERIM_S.nextval
                    ,fnd_global.conc_request_id
                    ,'I'
                    ,NULL
                    ,SYSDATE
                    ,FND_GLOBAL.USER_ID
                    ,SYSDATE
                    ,FND_GLOBAL.USER_ID
                   );    
      COMMIT;
      lv_adj_row_cnt := lv_adj_row_cnt + 1;
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Unique Index Violation :'||SQLERRM);
    END;
  END LOOP;
  
  lv_row_cnt:= lv_adj_row_cnt + lv_rcpt_row_cnt;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Row Count: ' || lv_row_cnt); 
EXCEPTION
  WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexpected Error :'||SQLERRM);  
END;

END XX_FIN_VPS_RCPT_INTERIM;
/