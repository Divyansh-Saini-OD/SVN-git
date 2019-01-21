SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CN_SUM_PKG
AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |      Oracle NAIO/Office Depot/Consulting Organization                          |
-- +================================================================================+
-- | Name       : XX_CN_SUM_PKG                                                     |
-- |                                                                                |
-- | Description: This procedure will summarize data into custom                    |
-- |              table XX_CN_SUM_TRX                                               |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date        Author                    Remarks                         |
-- |=======   ==========  =============             ================================|
-- |DRAFT 1A 12-OCT-2007 Sarah Maria Justina     Initial draft version              |
-- |1.0      18-OCT-2007 Sarah Maria Justina     Baselined asfter testing           |
-- |1.1      22-OCT-2007 Sarah Maria Justina     Incorporated Code Review Comments  |
-- |1.2      13-NOV-2007 Sarah Maria Justina     Changed Error Logging and bug fixes|
-- |                                             and removed Salesrep Div:TECHNOLOGY|
-- +================================================================================+
----------------------------
--Declaring Global Constants
----------------------------
   G_PROG_APPLICATION       CONSTANT CHAR (5)      := 'XXCRM';
   G_YES                    CONSTANT CHAR (1)      := 'Y';
   G_NO                     CONSTANT CHAR (1)      := 'N';
   G_TRX_TYPE               CONSTANT CHAR (3)      := 'SUM';
   G_TRX_DIV_BSD            CONSTANT CHAR (3)      := 'BSD';
   G_TRX_DIV_DPS            CONSTANT CHAR (3)      := 'DPS';
   
   G_TRX_DIV_FUR            CONSTANT VARCHAR2 (20) := 'FURNITURE';
   G_TRX_DIV_TECH           CONSTANT VARCHAR2 (20) := 'TECHNOLOGY';
   G_SUMM_MAIN_OM           CONSTANT VARCHAR2 (30) := 'SUMM_MAIN(OM)';
   G_SUMM_MAIN_AR           CONSTANT VARCHAR2 (30) := 'SUMM_MAIN(AR)';
   G_SUMM_MAIN_FAN          CONSTANT VARCHAR2 (30) := 'SUMM_MAIN(FAN)';
   G_OU_STATUS_ELIGIBLE     CONSTANT VARCHAR2 (20) := 'ELIGIBLE';
   G_OU_STATUS_NOT_ELIGIBLE CONSTANT VARCHAR2 (20) := 'NOT-ELIGIBLE';
   G_PROG_TYPE              CONSTANT VARCHAR2(100) := 'E1004F_CustomCollections_(Summarization)';

----------------------------
--Declaring Global Variables
----------------------------
   ex_curr_qtr_not_open             EXCEPTION;
   ex_invalid_cn_period_date        EXCEPTION;
   ex_invalid_start_date            EXCEPTION;

-- +===========================================================================================================+
-- | Name        :  notify_clawbacks
-- | Description :  This procedure is used to notify clawbacks.
-- | Parameters  :  p_start_date           DATE,
-- |                p_end_date             DATE,
-- |                p_process_audit_id     NUMBER
-- +===========================================================================================================+
   PROCEDURE SUMMARIZE_MAIN (
      x_errbuf        OUT  VARCHAR2,
      x_retcode       OUT  NUMBER,
      p_start_date         VARCHAR2,
      p_end_date           VARCHAR2
   )
   IS
   ln_proc_audit_id                 NUMBER; 
   ln_trx_count                     NUMBER;
   ln_current_qtr                   NUMBER;
   ln_message_code                  NUMBER;
   ln_count                         NUMBER;
   ln_batch_id                      NUMBER;
   
   L_LIMIT_SIZE            CONSTANT PLS_INTEGER               := 10000;
   
   lc_desc                          VARCHAR2 (240);
   lc_message_data                  VARCHAR2 (4000);
   lc_errmsg                        VARCHAR2 (4000);
   
   ld_start_date                    DATE;
   ld_end_date                      DATE;
   
   BEGIN
   ld_start_date                        := fnd_date.canonical_to_date(p_start_date);
   ld_end_date                          := fnd_date.canonical_to_date(p_end_date);
   xx_cn_util_pkg.display_out           (RPAD (' Office Depot', 100)|| 'Date:'|| SYSDATE);
   xx_cn_util_pkg.display_out           (LPAD ('OD Summarization Process',70)|| LPAD ('Page:1', 36));
   xx_cn_util_pkg.display_out           (RPAD (' ', 200, '_'));

   xx_cn_util_pkg.display_out           ('');
   xx_cn_util_pkg.display_out           ('');
   xx_cn_util_pkg.display_out           ('');
   xx_cn_util_pkg.display_log           ('<<Begin SUMMARIZE_MAIN>>');
   lc_desc                              := 'Summarization from '|| ld_start_date|| ' to '|| ld_end_date;
   
   xx_cn_util_pkg.display_log           ('Start Date:'||ld_start_date);
   xx_cn_util_pkg.display_log           ('End Date:'||ld_end_date);
   BEGIN
   -------------------------------------------------------------------
   --Checking if the Current Quarter is open for Summarization
   -------------------------------------------------------------------
   SELECT quarter_num
     INTO ln_current_qtr
     FROM cn_acc_period_statuses_v
    WHERE SYSDATE BETWEEN start_date AND end_date;
    
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
    RAISE ex_curr_qtr_not_open;
   END;
   -------------------------------------------------------------------------
   --Checking if Summarization Start Date belongs to the the Current Quarter
   -------------------------------------------------------------------------   
    SELECT COUNT (1)
      INTO ln_count
      FROM cn_acc_period_statuses_v
     WHERE quarter_num = ln_current_qtr
       AND ld_start_date BETWEEN start_date AND end_date;
   
   IF (ln_count = 0)
    THEN
      RAISE ex_invalid_cn_period_date;
   END IF;

   -------------------------------------------------------------------------
   --Checking if Summarization End Date belongs to the the Current Quarter
   -------------------------------------------------------------------------    
    SELECT COUNT (1)
      INTO ln_count
      FROM cn_acc_period_statuses_v
     WHERE quarter_num = ln_current_qtr
       AND ld_end_date BETWEEN start_date AND end_date;
      
   IF (ln_count = 0)
    THEN
      RAISE ex_invalid_cn_period_date;
   END IF;
   --------------------------------------------------------------------------------
   --Checking if Summarization Start Date is greater than the Current System Date
   --------------------------------------------------------------------------------    
   IF(ld_start_date > sysdate)
    THEN
      RAISE ex_invalid_start_date;
   END IF;
   -----------------------------------------------
   --Process Audit Begin Batch for SUMM_MAIN(OM)
   -----------------------------------------------
   xx_cn_util_pkg.begin_batch
                                        (p_parent_proc_audit_id      => NULL,
                                         x_process_audit_id          => ln_proc_audit_id,
                                         p_request_id                => fnd_global.conc_request_id,
                                         p_process_type              => G_SUMM_MAIN_OM,
                                         p_description               => lc_desc  
                                        );
                                    
   
  ln_trx_count := 0;
  
  SELECT xx_cn_summ_batch_s.nextval 
    INTO ln_batch_id
  FROM DUAL;
  
  UPDATE xx_cn_om_trx_v
   SET summ_batch_id = ln_batch_id
  WHERE summarized_flag = G_NO
   AND salesrep_assign_flag = G_YES
   AND (TO_DATE(rollup_date,'DD_MON-RRRR'), ship_to_address_id) 
   IN (
       SELECT DISTINCT TO_DATE(rollup_date,'DD_MON-RRRR'),
                       ship_to_address_id
         FROM xx_cn_sales_rep_asgn_v
      WHERE obsolete_flag = G_NO);
  
  INSERT INTO xx_cn_sum_trx
  (
  SUM_TRX_ID,              
  SALESREP_ID,              
  ROLLUP_DATE,              
  REVENUE_CLASS_ID,         
  REVENUE_TYPE,             
  ORG_ID,                   
  RESOURCE_ORG_ID,          
  DIVISION,                
  SALESREP_DIVISION,        
  ROLE_ID,                  
  COMP_GROUP_ID,            
  PROCESSED_PERIOD_ID,      
  TRANSACTION_AMOUNT,       
  TRX_TYPE,                 
  QUANTITY,                 
  TRANSACTION_CURRENCY_CODE,
  EXCHANGE_RATE,            
  DISCOUNT_PERCENTAGE,      
  MARGIN,                   
  SALESREP_NUMBER,          
  ROLLUP_FLAG,              
  SOURCE_DOC_TYPE,          
  OBJECT_VERSION_NUMBER,    
  OU_TRANSFER_STATUS, 
  COLLECT_ELIGIBLE,
  ATTRIBUTE1,               
  ATTRIBUTE2,               
  ATTRIBUTE3,               
  ATTRIBUTE4,               
  ATTRIBUTE5,               
  CONC_BATCH_ID,            
  PROCESS_AUDIT_ID,         
  REQUEST_ID,               
  PROGRAM_APPLICATION_ID,  
  CREATED_BY,               
  CREATION_DATE,           
  LAST_UPDATED_BY,          
  LAST_UPDATE_DATE,         
  LAST_UPDATE_LOGIN,        
  PROCESSED_DATE
  )
  SELECT xx_cn_sum_trx_s.nextval,OM.*
    FROM
     (SELECT   
              salesrep_asgn.salesrep_id as salesrep_id,
              om_view.rollup_date as rollup_date, 
              om_view.revenue_class_id as revenue_class_id, 
              salesrep_asgn.revenue_type as revenue_type,
              om_view.org_id as org_id,
              salesrep_asgn.resource_org_id as resource_org_id,
              om_view.division as division,
              salesrep_asgn.salesrep_division as salesrep_division,
              salesrep_asgn.resource_role_id as role_id, 
              salesrep_asgn.group_id as comp_group_id,
              om_view.processed_period_id as processed_period_id, 
              SUM (transaction_amount) as transaction_amount, 
              'SUM' AS trx_type,
              SUM (quantity) as quantity,
              om_view.transaction_currency_code as transaction_currency_code, 
              NULL as exchange_rate,
              NULL as discount_percentage,
              SUM (margin) as margin,
              salesrep_asgn.employee_number as salesrep_number,
              NULL as rollup_flag,
              om_view.source_doc_type as source_doc_type, 
              1 as object_version_number,
              (CASE salesrep_asgn.resource_org_id
                    WHEN om_view.org_id THEN G_OU_STATUS_NOT_ELIGIBLE
                    ELSE G_OU_STATUS_ELIGIBLE
                    END) AS ou_transfer_status,
              (CASE salesrep_asgn.resource_org_id
                    WHEN om_view.org_id THEN G_YES
                    ELSE G_NO
                    END) AS collect_eligible,              
              NULL as attribute1,
              NULL as attribute2,
              NULL as attribute3,
              NULL as attribute4,
              NULL as attribute5,
              NULL as conc_batch_id,
              ln_proc_audit_id as process_audit_id,
              fnd_global.conc_request_id as request_id,
              NULL AS program_application_id,
              TO_NUMBER (fnd_global.user_id) AS created_by,
              SYSDATE AS creation_date,
              TO_NUMBER (fnd_global.user_id) AS last_updated_by,
              SYSDATE AS last_update_date,
              TO_NUMBER (fnd_global.login_id) AS last_update_login,
              om_view.processed_date as processed_date
            FROM xx_cn_om_trx_v om_view, 
                 xx_cn_sales_rep_asgn_v salesrep_asgn
           WHERE TO_DATE(om_view.rollup_date,'DD-MON-RRRR') = TO_DATE(salesrep_asgn.rollup_date,'DD-MON-RRRR')
             AND om_view.ship_to_address_id = salesrep_asgn.ship_to_address_id
             AND 
             (CASE om_view.division 
                  WHEN   G_TRX_DIV_FUR THEN G_TRX_DIV_FUR
                  WHEN   G_TRX_DIV_DPS THEN G_TRX_DIV_DPS
                  WHEN   G_TRX_DIV_BSD THEN G_TRX_DIV_BSD
                  --WHEN   G_TRX_DIV_TECH THEN G_TRX_DIV_TECH
                  ELSE   G_TRX_DIV_BSD
                  END      ) = salesrep_asgn.division
             AND salesrep_asgn.obsolete_flag = G_NO
             AND om_view.summarized_flag = G_NO
             AND om_view.salesrep_assign_flag = G_YES
             AND om_view.summ_batch_id = ln_batch_id
        GROUP BY om_view.rollup_date,
                 salesrep_asgn.employee_number,
                 salesrep_asgn.salesrep_id,
                 om_view.revenue_class_id,
                 salesrep_asgn.revenue_type,
                 salesrep_asgn.resource_org_id,
                 salesrep_asgn.resource_role_id, 
                 salesrep_asgn.group_id,
                 om_view.processed_period_id, 
                 om_view.org_id,
                 salesrep_asgn.resource_org_id,
                 om_view.transaction_currency_code,
                 om_view.source_doc_type,
                 om_view.processed_date,
                 om_view.division,
               salesrep_asgn.salesrep_division) OM;
  
  UPDATE xx_cn_om_trx_v
   SET summarized_flag = G_YES
  WHERE summarized_flag = G_NO
   AND salesrep_assign_flag = G_YES
   AND summ_batch_id = ln_batch_id
   AND (TO_DATE(rollup_date,'DD_MON-RRRR'), ship_to_address_id) 
   IN (
       SELECT DISTINCT TO_DATE(rollup_date,'DD_MON-RRRR'),
                       ship_to_address_id
         FROM xx_cn_sales_rep_asgn_v
        WHERE obsolete_flag = G_NO);
            
  ln_trx_count                          := SQL%ROWCOUNT;

  lc_message_data                       := 'Number of Order lines summarized:'||ln_trx_count;
  xx_cn_util_pkg.WRITE                  ('SUMMARIZE_MAIN: ' || lc_message_data,'LOG');
  xx_cn_util_pkg.display_log            ('SUMMARIZE_MAIN: ' || lc_message_data);
  xx_cn_util_pkg.display_out            (' Number of Order lines summarized                :              '|| LPAD(ln_trx_count,15));
  xx_cn_util_pkg.display_out            ('');
  
  COMMIT;
  xx_cn_util_pkg.end_batch              (ln_proc_audit_id);
  
   -----------------------------------------------
   --Process Audit Begin Batch for SUMM_MAIN(AR)
   -----------------------------------------------
   xx_cn_util_pkg.begin_batch
                                        (p_parent_proc_audit_id      => NULL,
                                         x_process_audit_id          => ln_proc_audit_id,
                                         p_request_id                => fnd_global.conc_request_id,
                                         p_process_type              => G_SUMM_MAIN_AR,
                                         p_description               => lc_desc  
                                        );
                                    
   
  -----------------------------------------------
  --Begin Insert into XX_CN_SUM_TRX for AR
  -----------------------------------------------
  ln_trx_count := 0;
  
  SELECT xx_cn_summ_batch_s.nextval 
    INTO ln_batch_id
    FROM DUAL;
  
  UPDATE xx_cn_ar_trx_v
   SET summ_batch_id = ln_batch_id
  WHERE summarized_flag = G_NO
   AND salesrep_assign_flag = G_YES
   AND (TO_DATE(rollup_date,'DD_MON-RRRR'), ship_to_address_id) 
   IN (
       SELECT DISTINCT TO_DATE(rollup_date,'DD_MON-RRRR'),
                       ship_to_address_id
         FROM xx_cn_sales_rep_asgn_v
      WHERE obsolete_flag = G_NO);
  
  INSERT INTO xx_cn_sum_trx
    (
    SUM_TRX_ID,              
    SALESREP_ID,              
    ROLLUP_DATE,              
    REVENUE_CLASS_ID,         
    REVENUE_TYPE,             
    ORG_ID,                   
    RESOURCE_ORG_ID,          
    DIVISION,                
    SALESREP_DIVISION,        
    ROLE_ID,                  
    COMP_GROUP_ID,            
    PROCESSED_PERIOD_ID,      
    TRANSACTION_AMOUNT,       
    TRX_TYPE,                 
    QUANTITY,                 
    TRANSACTION_CURRENCY_CODE,
    EXCHANGE_RATE,            
    DISCOUNT_PERCENTAGE,      
    MARGIN,                   
    SALESREP_NUMBER,          
    ROLLUP_FLAG,              
    SOURCE_DOC_TYPE,          
    OBJECT_VERSION_NUMBER,    
    OU_TRANSFER_STATUS, 
    COLLECT_ELIGIBLE,
    ATTRIBUTE1,               
    ATTRIBUTE2,               
    ATTRIBUTE3,               
    ATTRIBUTE4,               
    ATTRIBUTE5,               
    CONC_BATCH_ID,            
    PROCESS_AUDIT_ID,         
    REQUEST_ID,               
    PROGRAM_APPLICATION_ID,  
    CREATED_BY,               
    CREATION_DATE,           
    LAST_UPDATED_BY,          
    LAST_UPDATE_DATE,         
    LAST_UPDATE_LOGIN,        
    PROCESSED_DATE
  )
  SELECT xx_cn_sum_trx_s.nextval,AR.*
         FROM
       (SELECT 
             salesrep_asgn.salesrep_id as salesrep_id,
             ar_view.rollup_date, 
             ar_view.revenue_class_id, 
             salesrep_asgn.revenue_type,
             ar_view.org_id,
             salesrep_asgn.resource_org_id,
             ar_view.division as division,
             salesrep_asgn.salesrep_division as salesrep_division,
             salesrep_asgn.resource_role_id, 
             salesrep_asgn.group_id,
             ar_view.processed_period_id, 
             SUM (transaction_amount) as transaction_amount, 
             'SUM' AS trx_type,
             SUM (quantity),
             ar_view.transaction_currency_code, 
             NULL as exchange_rate,
             NULL as discount_percentage,
             SUM (margin) as margin,
             salesrep_asgn.employee_number,
             NULL as rollup_flag,
             ar_view.source_doc_type, 
             1 as object_version_number,
              (CASE salesrep_asgn.resource_org_id
                    WHEN ar_view.org_id THEN G_OU_STATUS_NOT_ELIGIBLE
                    ELSE G_OU_STATUS_ELIGIBLE
                    END)AS ou_transfer_status,
              (CASE salesrep_asgn.resource_org_id
                    WHEN ar_view.org_id THEN G_YES
                    ELSE G_NO
                    END) AS collect_eligible,  
             NULL as attribute1,
             NULL as attribute2,
             NULL as attribute3,
             NULL as attribute4,
             NULL as attribute5,
             NULL as conc_batch_id,
             ln_proc_audit_id as process_audit_id,
             fnd_global.conc_request_id as request_id,
             NULL as program_application_id,
             TO_NUMBER (fnd_global.user_id) AS created_by,
             SYSDATE AS creation_date,
             TO_NUMBER (fnd_global.user_id) AS last_updated_by,
             SYSDATE AS last_update_date,
             TO_NUMBER (fnd_global.login_id) AS last_update_login,
             ar_view.processed_date as processed_date
           FROM xx_cn_ar_trx_v ar_view, 
                xx_cn_sales_rep_asgn_v salesrep_asgn
          WHERE TO_DATE(ar_view.rollup_date,'DD-MON-RRRR') = TO_DATE(salesrep_asgn.rollup_date,'DD-MON-RRRR')
            AND ar_view.ship_to_address_id = salesrep_asgn.ship_to_address_id
            AND 
             (CASE ar_view.division 
                  WHEN   G_TRX_DIV_FUR THEN G_TRX_DIV_FUR
                  WHEN   G_TRX_DIV_DPS THEN G_TRX_DIV_DPS
                  WHEN   G_TRX_DIV_BSD THEN G_TRX_DIV_BSD
                  --WHEN   G_TRX_DIV_TECH THEN G_TRX_DIV_TECH
                  ELSE   G_TRX_DIV_BSD
                  END      ) = salesrep_asgn.division
            AND salesrep_asgn.obsolete_flag = G_NO
            AND ar_view.summarized_flag = G_NO
            AND ar_view.salesrep_assign_flag = G_YES
            AND ar_view.summ_batch_id = ln_batch_id
       GROUP BY ar_view.rollup_date,
                salesrep_asgn.employee_number,
                salesrep_asgn.salesrep_id,
                ar_view.revenue_class_id,
                salesrep_asgn.revenue_type,
                salesrep_asgn.resource_org_id,
                salesrep_asgn.resource_role_id, 
                salesrep_asgn.group_id,
                ar_view.processed_period_id, 
                ar_view.org_id,
                salesrep_asgn.resource_org_id,
                ar_view.transaction_currency_code,
                ar_view.source_doc_type,
                ar_view.processed_date,
                ar_view.division,
            salesrep_asgn.salesrep_division) AR;
  
  UPDATE xx_cn_ar_trx_v
   SET summarized_flag = G_YES
  WHERE summarized_flag = G_NO
   AND salesrep_assign_flag = G_YES
   AND summ_batch_id = ln_batch_id
   AND (TO_DATE(rollup_date,'DD_MON-RRRR'), ship_to_address_id) 
   IN (
       SELECT DISTINCT TO_DATE(rollup_date,'DD_MON-RRRR'),
                       ship_to_address_id
         FROM xx_cn_sales_rep_asgn_v
        WHERE obsolete_flag = G_NO);
              
  ln_trx_count                          := SQL%ROWCOUNT;

  lc_message_data                       := 'Number of AR lines summarized:'||ln_trx_count;
  xx_cn_util_pkg.WRITE                  ('SUMMARIZE_MAIN: ' || lc_message_data,'LOG');
  xx_cn_util_pkg.display_log            ('SUMMARIZE_MAIN: ' || lc_message_data);
  xx_cn_util_pkg.display_out            (' Number of AR lines summarized                   :              '|| LPAD(ln_trx_count,15));
  xx_cn_util_pkg.display_out            ('');
  
  COMMIT;
  xx_cn_util_pkg.end_batch              (ln_proc_audit_id);
   
   -----------------------------------------------
   --Process Audit Begin Batch for SUMM_MAIN(FAN)
   -----------------------------------------------
   xx_cn_util_pkg.begin_batch
                                        (p_parent_proc_audit_id      => NULL,
                                         x_process_audit_id          => ln_proc_audit_id,
                                         p_request_id                => fnd_global.conc_request_id,
                                         p_process_type              => G_SUMM_MAIN_FAN,
                                         p_description               => lc_desc  
                                        );
                                    
   
  -----------------------------------------------
  --Begin Insert into XX_CN_SUM_TRX for Fanatic
  -----------------------------------------------
  ln_trx_count := 0;
  
  SELECT xx_cn_summ_batch_s.nextval 
    INTO ln_batch_id
  FROM DUAL;
  
  UPDATE xx_cn_fan_trx_v
   SET summ_batch_id = ln_batch_id
  WHERE summarized_flag = G_NO
   AND salesrep_assign_flag = G_YES
   AND (TO_DATE(rollup_date,'DD_MON-RRRR'), ship_to_address_id) 
   IN (
       SELECT DISTINCT TO_DATE(rollup_date,'DD_MON-RRRR'),
                       ship_to_address_id
         FROM xx_cn_sales_rep_asgn_v
      WHERE obsolete_flag = G_NO);
      
  INSERT INTO xx_cn_sum_trx
      (
      SUM_TRX_ID,              
      SALESREP_ID,              
      ROLLUP_DATE,              
      REVENUE_CLASS_ID,         
      REVENUE_TYPE,             
      ORG_ID,                   
      RESOURCE_ORG_ID,          
      DIVISION,                
      SALESREP_DIVISION,        
      ROLE_ID,                  
      COMP_GROUP_ID,            
      PROCESSED_PERIOD_ID,      
      TRANSACTION_AMOUNT,       
      TRX_TYPE,                 
      QUANTITY,                 
      TRANSACTION_CURRENCY_CODE,
      EXCHANGE_RATE,            
      DISCOUNT_PERCENTAGE,      
      MARGIN,                   
      SALESREP_NUMBER,          
      ROLLUP_FLAG,              
      SOURCE_DOC_TYPE,          
      OBJECT_VERSION_NUMBER,    
      OU_TRANSFER_STATUS,  
      COLLECT_ELIGIBLE,
      ATTRIBUTE1,               
      ATTRIBUTE2,               
      ATTRIBUTE3,               
      ATTRIBUTE4,               
      ATTRIBUTE5,               
      CONC_BATCH_ID,            
      PROCESS_AUDIT_ID,         
      REQUEST_ID,               
      PROGRAM_APPLICATION_ID,  
      CREATED_BY,               
      CREATION_DATE,           
      LAST_UPDATED_BY,          
      LAST_UPDATE_DATE,         
      LAST_UPDATE_LOGIN,        
      PROCESSED_DATE
  )
  SELECT xx_cn_sum_trx_s.nextval,FAN.*
    FROM
       (SELECT 
              salesrep_asgn.salesrep_id as salesrep_id,
              fan_view.rollup_date, 
              fan_view.revenue_class_id, 
              salesrep_asgn.revenue_type,
              fan_view.org_id,
              salesrep_asgn.resource_org_id,
              fan_view.division as division,
              salesrep_asgn.salesrep_division as salesrep_division,
              salesrep_asgn.resource_role_id, 
              salesrep_asgn.group_id,
              fan_view.processed_period_id, 
              SUM (transaction_amount) as transaction_amount, 
              'SUM' AS trx_type,
              SUM (quantity),
              fan_view.transaction_currency_code, 
              NULL as exchange_rate,
              NULL as discount_percentage,
              SUM (margin) as margin,
              salesrep_asgn.employee_number,
              NULL as rollup_flag,
              fan_view.source_doc_type, 
              1 as object_version_number,
              (CASE salesrep_asgn.resource_org_id
                    WHEN fan_view.org_id THEN G_OU_STATUS_NOT_ELIGIBLE
                    ELSE G_OU_STATUS_ELIGIBLE
                    END) AS ou_transfer_status,
              (CASE salesrep_asgn.resource_org_id
                    WHEN fan_view.org_id THEN G_YES
                    ELSE G_NO
                    END) AS collect_eligible,  
              NULL as attribute1,
              NULL as attribute2,
              NULL as attribute3,
              NULL as attribute4,
              NULL as attribute5,
              NULL as conc_batch_id,
              ln_proc_audit_id as process_audit_id,
              fnd_global.conc_request_id as request_id,
              NULL AS program_application_id,
              TO_NUMBER (fnd_global.user_id) AS created_by,
              SYSDATE AS creation_date,
              TO_NUMBER (fnd_global.user_id) AS last_updated_by,
              SYSDATE AS last_update_date,
              TO_NUMBER (fnd_global.login_id) AS last_update_login,
              fan_view.processed_date as processed_date
            FROM xx_cn_fan_trx_v fan_view, 
                 xx_cn_sales_rep_asgn_v salesrep_asgn
           WHERE TO_DATE(fan_view.rollup_date,'DD-MON-RRRR') = TO_DATE(salesrep_asgn.rollup_date,'DD-MON-RRRR')
             AND fan_view.ship_to_address_id = salesrep_asgn.ship_to_address_id
             AND 
             (CASE fan_view.division 
                  WHEN   G_TRX_DIV_FUR THEN G_TRX_DIV_FUR
                  WHEN   G_TRX_DIV_DPS THEN G_TRX_DIV_DPS
                  WHEN   G_TRX_DIV_BSD THEN G_TRX_DIV_BSD
                  --WHEN   G_TRX_DIV_TECH THEN G_TRX_DIV_TECH
                  ELSE   G_TRX_DIV_BSD
                  END      ) = salesrep_asgn.division
             AND salesrep_asgn.obsolete_flag = G_NO
             AND fan_view.summarized_flag = G_NO
             AND fan_view.salesrep_assign_flag = G_YES
             AND fan_view.summ_batch_id = ln_batch_id
        GROUP BY fan_view.rollup_date,
                 salesrep_asgn.employee_number,
                 salesrep_asgn.salesrep_id,
                 fan_view.revenue_class_id,
                 salesrep_asgn.revenue_type,
                 salesrep_asgn.resource_org_id,
                 salesrep_asgn.resource_role_id, 
                 salesrep_asgn.group_id,
                 fan_view.processed_period_id, 
                 fan_view.org_id,
                 salesrep_asgn.resource_org_id,
                 fan_view.transaction_currency_code,
                 fan_view.source_doc_type,
                 fan_view.processed_date,
                 fan_view.division,
               salesrep_asgn.salesrep_division) FAN;
  
  UPDATE xx_cn_fan_trx_v
   SET summarized_flag = G_YES
  WHERE summarized_flag = G_NO
   AND salesrep_assign_flag = G_YES
   AND summ_batch_id = ln_batch_id
   AND (TO_DATE(rollup_date,'DD_MON-RRRR'), ship_to_address_id) 
   IN (
       SELECT DISTINCT TO_DATE(rollup_date,'DD_MON-RRRR'),
                       ship_to_address_id
         FROM xx_cn_sales_rep_asgn_v
        WHERE obsolete_flag = G_NO);
              
  ln_trx_count                          := SQL%ROWCOUNT;
  
  lc_message_data                       := 'Number of Fanatic lines summarized:'||ln_trx_count;
  xx_cn_util_pkg.WRITE                  ('SUMMARIZE_MAIN: ' || lc_message_data,'LOG');
  xx_cn_util_pkg.display_log            ('SUMMARIZE_MAIN: ' || lc_message_data);
  xx_cn_util_pkg.display_out            (' Number of Fanatic lines summarized              :              '|| LPAD(ln_trx_count,15));
  xx_cn_util_pkg.display_out            ('');
  
  COMMIT;
  xx_cn_util_pkg.end_batch              (ln_proc_audit_id);  
   
  xx_cn_util_pkg.display_out            (LPAD ('*************End of Program************************',86));
  xx_cn_util_pkg.display_out            (RPAD (' ', 230, '_'));
 
  EXCEPTION
  WHEN ex_curr_qtr_not_open THEN
  ROLLBACK;
      ln_message_code                   := -1;
      fnd_message.set_name              ('XXCRM', 'XX_OIC_0026_CURR_QTR_NOT_OPEN');
      lc_message_data                   := fnd_message.get;
      xx_cn_util_pkg.log_error
                                        (
                                        p_prog_name      => 'XX_CN_SUM_PKG.SUMMARIZE_MAIN',
                                        p_prog_type      => G_PROG_TYPE,
                                        p_prog_id        => fnd_global.conc_request_id,
                                        p_exception      => 'XX_CN_SUM_PKG.SUMMARIZE_MAIN',
                                        p_message        => lc_message_data,
                                        p_code           => ln_message_code,
                                        p_err_code       => 'XX_OIC_0026_CURR_QTR_NOT_OPEN'
                                        );
      lc_errmsg                         := 'Procedure: SUMMARIZE_MAIN: ' || lc_message_data;
      xx_cn_util_pkg.DEBUG              ('--Error:' || lc_errmsg);
      xx_cn_util_pkg.display_log        ('--Error:' || lc_errmsg);
      xx_cn_util_pkg.display_log        ('<<End SUMMARIZE_MAIN>>');
      x_retcode                         := 2;
      x_errbuf                          := 'Procedure: SUMMARIZE_MAIN: ' || lc_message_data;
  WHEN ex_invalid_cn_period_date THEN
  ROLLBACK;
      ln_message_code                   := -1;
      fnd_message.set_name              ('XXCRM', 'XX_OIC_0027_INVALID_SUMM_DATES');
      lc_message_data                   := fnd_message.get;
      xx_cn_util_pkg.log_error
                                        (
                                        p_prog_name      => 'XX_CN_SUM_PKG.SUMMARIZE_MAIN',
                                        p_prog_type      => G_PROG_TYPE,
                                        p_prog_id        => fnd_global.conc_request_id,
                                        p_exception      => 'XX_CN_SUM_PKG.SUMMARIZE_MAIN',
                                        p_message        => lc_message_data,
                                        p_code           => ln_message_code,
                                        p_err_code       => 'XX_OIC_0027_INVALID_SUMM_DATES'
                                        );
      lc_errmsg                         := 'Procedure: SUMMARIZE_MAIN: ' || lc_message_data;
      xx_cn_util_pkg.DEBUG              ('--Error:' || lc_errmsg);
      xx_cn_util_pkg.display_log        ('--Error:' || lc_errmsg);
      xx_cn_util_pkg.display_log        ('<<End SUMMARIZE_MAIN>>');
      x_retcode                         := 2;
      x_errbuf                          := 'Procedure: SUMMARIZE_MAIN: ' || lc_message_data;  
  WHEN ex_invalid_start_date THEN
  ROLLBACK;
      ln_message_code                   := -1;
      fnd_message.set_name              ('XXCRM', 'XX_OIC_0028_INVALID_START_DATE');
      lc_message_data                   := fnd_message.get;
      xx_cn_util_pkg.log_error
                                        (
                                        p_prog_name      => 'XX_CN_SUM_PKG.SUMMARIZE_MAIN',
                                        p_prog_type      => G_PROG_TYPE,
                                        p_prog_id        => fnd_global.conc_request_id,
                                        p_exception      => 'XX_CN_SUM_PKG.SUMMARIZE_MAIN',
                                        p_message        => lc_message_data,
                                        p_code           => ln_message_code,
                                        p_err_code       => 'XX_OIC_0028_INVALID_START_DATE'
                                        );
      lc_errmsg                         := 'Procedure: SUMMARIZE_MAIN: ' || lc_message_data;
      xx_cn_util_pkg.DEBUG              ('--Error:' || lc_errmsg);
      xx_cn_util_pkg.display_log        ('--Error:' || lc_errmsg);
      xx_cn_util_pkg.display_log        ('<<End SUMMARIZE_MAIN>>');
      x_retcode                         := 2;
      x_errbuf                          := 'Procedure: SUMMARIZE_MAIN: ' || lc_message_data;  
  WHEN OTHERS THEN
    ROLLBACK;
      ln_message_code                   := -1;
      fnd_message.set_name              ('XXCRM', 'XX_OIC_0010_UNEXPECTED_ERR');
      fnd_message.set_token             ('SQL_CODE', SQLCODE);
      fnd_message.set_token             ('SQL_ERR', SQLERRM);
      lc_message_data                   := fnd_message.get;
      xx_cn_util_pkg.log_error
                                        (p_prog_name      => 'XX_CN_SUM_PKG.SUMMARIZE_MAIN',
                                        p_prog_type      => G_PROG_TYPE,
                                        p_prog_id        => fnd_global.conc_request_id,
                                        p_exception      => 'XX_CN_SUM_PKG.SUMMARIZE_MAIN',
                                        p_message        => lc_message_data,
                                        p_code           => ln_message_code,
                                        p_err_code       => 'XX_OIC_0010_UNEXPECTED_ERR'
                                        );
      lc_errmsg                         := 'Procedure: SUMMARIZE_MAIN: ' || lc_message_data;
      xx_cn_util_pkg.DEBUG              ('--Error:' || lc_errmsg);
      xx_cn_util_pkg.display_log        ('--Error:' || lc_errmsg);
      xx_cn_util_pkg.display_log        ('<<End SUMMARIZE_MAIN>>');
      x_retcode                         := 2;
      x_errbuf                          := 'Procedure: SUMMARIZE_MAIN: ' || lc_message_data;  
  END SUMMARIZE_MAIN;
END XX_CN_SUM_PKG;
/

SHOW ERRORS
EXIT;
