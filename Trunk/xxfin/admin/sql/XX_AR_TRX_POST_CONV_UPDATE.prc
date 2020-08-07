SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PROCEDURE XX_AR_TRX_POST_CONV_UPDATE

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PROCEDURE XX_AR_TRX_POST_CONV_UPDATE (retcode OUT NUMBER
                                                       ,errbuf  OUT VARCHAR2) AS

-- +====================================================================================+
-- |                  Office Depot - Project Simplify                                   |
-- +====================================================================================+
-- |                                                                                    |
-- |Change Record:                                                                      |
-- |===============                                                                     |
-- |Version   Date          Author              Remarks                                 |
-- |=======   ==========   =============        ========================================|
-- |1.0       18-JUL-2007                       Initial version                         |
-- |1.1       02-FEB-2009  Anitha Devarajulu    Fix for Defect 13012 (10304 and 12227)  |
-- |1.2       05-FEB-2009  Anitha Devarajulu    Added the WHERE condition for the       |
-- |                                            First Update Statement                  |
-- |1.3       06-Nov-2009  Vasu Raparla         Removed Schema References for R12.2     |
-- +====================================================================================+
-- | Description: Office Depot needs to exclude all legacy AR transactions converted    |
-- |              from the consolidated billing process. Oracle has no direct solution  |
-- |              to address this requirement. Office Depot has agreed for a one off    |
-- |              post conversion update script that flags all the AR transactions that |
-- |              are converted and identified using the transaction source             |
-- |              "CONVERSION_OD" . The script for all transactions that belon to ORG_ID|
-- |              141(US) and 161(CANADA)                                               |
-- |   Assumptions: AR must have invoices sourced from  CONVERSION_OD at the time of    |
-- |                execution of this program                                           |
-- |  Technical Information:                                                            |
-- |   Oracle Delivered Consolidated Billing Package -arp_consinv uses the field        |
-- |  "AR_PAYMENTS_SCHEDULES_ALL.EXCLUDE_FROM_CONS_BILLING_FLAG within the procedure    |
-- |   "GENERATE" to exclude all installments from summary if the value is "Y".         |
-- |   Office Depot converted invoices will not have more than one installment. So we   |
-- |   use this flag and update to "Y" that way they are excluded from the summary      |
-- |   billing process.                                                                 |
-- +====================================================================================+
/*
     TYPE tab_ps_id IS TABLE OF AR_PAYMENT_SCHEDULES_ALL.PAYMENT_SCHEDULE_ID%TYPE;

     ln_tab_ps_id tab_ps_id;
     
     upd_rows NUMBER :=0;
     
     CURSOR c_org is 
     SELECT organization_id, name 
     from hr_operating_units 
     order by organization_id;

     CURSOR dset_inv(n_org_id IN NUMBER) IS
      SELECT arps.payment_schedule_id
        FROM ra_customer_trx_all      ratrx
            ,ra_batch_sources_all     rabatch
            ,ar_payment_schedules_all arps
       WHERE rabatch.name          ='CONVERSION_OD'
         AND rabatch.org_id        =n_org_id
         AND ratrx.batch_source_id =rabatch.batch_source_id
         AND arps.customer_trx_id  =ratrx.customer_trx_id
         AND arps.exclude_from_cons_bill_flag IS NULL
       FOR UPDATE;        
  */     
  --Execution Starts...        

-- Starting Added for defect 12227

  ln_user_id fnd_user.user_id%TYPE;

  CURSOR lcu_batch_source
  IS
   (SELECT org_id,
           batch_source_id
     FROM  ra_batch_sources_all 
     WHERE NAME ='CONVERSION_OD') ; 

-- Ending Added for defect 12227

  BEGIN

    BEGIN

       SELECT user_id
       INTO   ln_user_id
       FROM   fnd_user
       WHERE  user_name = 'CONVERSION';

       UPDATE ar_payment_schedules_all
       SET    exclude_from_cons_bill_flag = 'Y'
             ,last_updated_by             = fnd_global.user_id
             ,last_update_date            = SYSDATE
       WHERE  created_by                  = ln_user_id;      -- created by CONVERSION user

       FND_FILE.PUT_LINE(FND_FILE.LOG,'Updating ar_payment_schedules_all with exclude_from_cons_bill_flag = Y '
                                      ||' Count:  ' || SQL%ROWCOUNT );
    EXCEPTION
       WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'XX_AR_TRX_POST_CONV_UPDATE - Process');
          FND_FILE.PUT_LINE(FND_FILE.LOG,'XX_AR_TRX_POST_CONV_UPDATE - Error in setting the excl_from_cons_billing_flag');
          FND_FILE.PUT_LINE(FND_FILE.LOG,'XX_AR_TRX_POST_CONV_UPDATE - From ar_payment_schedules_all table to Y');
          FND_FILE.PUT_LINE(FND_FILE.LOG,'XX_AR_TRX_POST_CONV_UPDATE : '||SUBSTR(SQLERRM,1,2000));
          ROLLBACK;
          RAISE;
    END;

/*
 FOR n_org_rec in c_org
  LOOP
       FND_FILE.PUT_LINE(FND_FILE.LOG,'');  
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Operating Unit:'||n_org_rec.name);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'===============');  
       
     OPEN dset_inv(n_org_rec.organization_id);
      LOOP
       FETCH dset_inv BULK COLLECT INTO ln_tab_ps_id; 

       EXIT WHEN ln_tab_ps_id.COUNT =0;   
          
       FND_FILE.PUT_LINE(FND_FILE.LOG,'');
       FND_FILE.PUT_LINE(FND_FILE.LOG,' Total '||n_org_rec.name||' invoices ready for update : '||ln_tab_ps_id.COUNT);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'=================================');

        FOR i IN 1..ln_tab_ps_id.count
         LOOP
          UPDATE ar_payment_schedules_all
             SET exclude_from_cons_bill_flag ='Y',
                 last_update_date = SYSDATE               
           WHERE payment_schedule_id = ln_tab_ps_id(i);
           
          IF SQL%ROWCOUNT >0 THEN
            upd_rows :=upd_rows+1;
          END IF; 
         END LOOP;                       
       END LOOP;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Total:'||n_org_rec.name||' invoices updated : '||upd_rows);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'=================================');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'');        
       upd_rows :=0;
              
       CLOSE dset_inv;         
  END LOOP; 
*/  

-- Starting Added for E0055 - defect 10304
    BEGIN

       UPDATE ar_payment_schedules_all
       SET    last_update_date = trx_date    -- set activity date to trx date
       WHERE  amount_due_remaining < 0       -- credit balance
       AND    status     = 'OP'              -- open status
       AND    created_by = ln_user_id;        -- created by CONVERSION user

       FND_FILE.PUT_LINE(FND_FILE.LOG,'Updating ar_payment_schedules_all with status =OP '
                                      ||' Count:  ' || SQL%ROWCOUNT );

    EXCEPTION
       WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'XX_AR_TRX_POST_CONV_UPDATE - Process');
          FND_FILE.PUT_LINE(FND_FILE.LOG,'XX_AR_TRX_POST_CONV_UPDATE - Error in setting the last_update_date');
          FND_FILE.PUT_LINE(FND_FILE.LOG,'XX_AR_TRX_POST_CONV_UPDATE - From ar_payment_schedules_all table to trx_date');
          FND_FILE.PUT_LINE(FND_FILE.LOG,'XX_AR_TRX_POST_CONV_UPDATE : '||SUBSTR(SQLERRM,1,2000));
          ROLLBACK;
          RAISE;
    END;
-- Ending Added for E0055 - defect 10304

    COMMIT WORK;

-- Starting Added for defect 12227
    BEGIN
       FOR lcu_batch_source_rec in lcu_batch_source
       LOOP

         -- Updating converted Invoices.
          UPDATE /*+ index(RCT XX_AR_CUSTOMER_TRX_N4) */ ra_customer_trx_all RCT
          SET    RCT.attribute15     = 'P'
                ,RCT.PRINTING_OPTION ='NOT'
          WHERE  RCT.batch_source_id = lcu_batch_source_rec.batch_source_id 
          AND    org_id = lcu_batch_source_rec.org_id 
          AND    RCT.attribute15 IS NULL ;

         FND_FILE.PUT_LINE(FND_FILE.LOG,'UPDATING ORG ID : '  || lcu_batch_source_rec.org_id 
                                       ||' Batch Source Id : '|| lcu_batch_source_rec.batch_source_id 
                                       ||' Count:  '||SQL%ROWCOUNT );
       END LOOP;

    EXCEPTION
       WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'XX_AR_TRX_POST_CONV_UPDATE - Process');
          FND_FILE.PUT_LINE(FND_FILE.LOG,'XX_AR_TRX_POST_CONV_UPDATE - Error in setting the Attribute15 and Printing_Option');
          FND_FILE.PUT_LINE(FND_FILE.LOG,'XX_AR_TRX_POST_CONV_UPDATE - From ra_customer_trx_all table to P and NOT');
          FND_FILE.PUT_LINE(FND_FILE.LOG,'XX_AR_TRX_POST_CONV_UPDATE : '||SUBSTR(SQLERRM,1,2000));
          ROLLBACK;
          RAISE;
    END;

    COMMIT;

-- Ending Added for defect 12227

END XX_AR_TRX_POST_CONV_UPDATE;
/
show err