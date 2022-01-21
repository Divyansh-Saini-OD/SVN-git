create or replace 
PACKAGE BODY XXOD_OMX_AR_UPD_DUEDATE_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                          	  |
  -- +============================================================================================+
  -- |  Name:  XXOD_OMX_AR_UPD_DUEDATE_PKG                                                     	  |
  -- |                                                                                            |
  -- |  Description:  This package body updates the Due Date of  all OMX ODN invoices             | 
  -- |                						        		                                      |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         28-FEB-2017  Punit Gupta      Initial version                                  |
  -- +============================================================================================+
  
  
PROCEDURE post_process_invoices(errbuff OUT VARCHAR2,
                                retcode OUT VARCHAR2)
IS
  CURSOR c1 
  IS
  SELECT INV_NO
  FROM   XXOD_OMX_CNV_AR_TRX_STG
  WHERE  process_flag = 4;
  
BEGIN

  FOR i_rec in c1
  LOOP
         BEGIN   
          UPDATE ar_payment_schedules_all aps
              SET aps.due_date=NVL((SELECT TRUNC(TO_DATE(rct.interface_header_attribute14,'DD-MON-YY HH:MI:SS'))
                                  FROM ra_customer_trx_all rct
                                  WHERE 1=1
                                    AND rct.trx_number=i_rec.INV_NO
                                    AND rct.customer_trx_id = aps.customer_trx_id
                                    ),aps.due_date)
                  ,aps.last_update_date = SYSDATE
                  ,aps.last_updated_by = fnd_global.user_id
                  ,aps.last_update_login = fnd_global.login_id	
            WHERE EXISTS (SELECT customer_trx_id
                            FROM ra_customer_trx_all rct
                           WHERE 1=1
                             AND rct.trx_number=i_rec.INV_NO
                             AND rct.customer_trx_id=aps.customer_trx_id
                           )
              AND aps.status='OP';
			
        IF(SQL%ROWCOUNT > 0) THEN
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Due_Date Successfully Update for Trx_Number: ' || i_rec.INV_NO);
       END IF;           			
			  
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Update Due Date No Data Found:'||SQLERRM);
            NULL;
          WHEN TOO_MANY_ROWS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Update Due Date TOO Many Rows:'||i_rec.INV_NO||SQLERRM);
            NULL;
          WHEN OTHERS THEN 
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Update Due Date '||SQLERRM);
            NULL;
        END;
      COMMIT;
  END LOOP;
END post_process_invoices; 

END XXOD_OMX_AR_UPD_DUEDATE_PKG ;
/