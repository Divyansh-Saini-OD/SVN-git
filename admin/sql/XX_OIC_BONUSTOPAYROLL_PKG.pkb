SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_OIC_BONUSTOPAYROLL_PKG
        -- +===================================================================+
        -- |                  Office Depot - Project Simplify                  |
        -- |                       WIPRO Technologies                          |
        -- +===================================================================+
        -- | Name       :  XX_OIC_BONUSTOPAYROLL_PKG                           |
        -- | Rice ID    :  I0607_IncentiveAndBonusToPayroll                    |
        -- | Description:  This package contains procedure to update audit     |
        -- |               history table.                                      |
        -- |                                                                   |
        -- |Change Record:                                                     |
        -- |===============                                                    |
        -- |Version   Date        Author           Remarks                     |
        -- |=======   ==========  =============    ============================|
        -- |1.a      23-SEP-2007  Rizwan           Initial draft version       |
        -- |1.b      05-OCT-2007  Rizwan           Modified insert script to   |
        -- |                                       add ORG ID column.          |
        -- |1.0      09-NOV-2007  Rizwan           Modified code to use CRM    |
        -- |                                       Error Log API.              |
        -- |1.1      27-NOV-2007  Rizwan           Modified code to use new    |
        -- |                                       error code.                 |
        -- +===================================================================+
AS
        -- +===================================================================+
        -- | Name             : Maintain_Audit_History                         |
        -- | Description      : This procedure update the status of Payroll    |
        -- |                    transmission in the audit history table at     |
        -- |                    various stages.                                |
        -- |                                                                   |
        -- | parameters :      p_payrun (Payrun||':'||Operating Unit)          |                                        |
        -- |                   p_bpel_transfer_date                            |
        -- |                   p_transfer_status                               |
        -- |                   p_reason                                        |
        -- |                   p_log                                           |
        -- |                   p_user_name                                     |
        -- |                   p_resp_name                                     |
        -- |                                                                   |
        -- | retutns:          x_status                                        |
        -- |                   x_message                                       |
        -- |                                                                   |
        -- +===================================================================+

 PROCEDURE Maintain_Audit_History (p_payrun                   IN      VARCHAR2
                                  ,p_bpel_transfer_date       IN      DATE
                                  ,p_transfer_status          IN      VARCHAR2
                                  ,p_reason                   IN      VARCHAR2
                                  ,p_log                      IN      VARCHAR2
                                  ,p_user_name                IN      VARCHAR2
                                  ,p_resp_name                IN      VARCHAR2 
                                  ,x_status                   OUT     VARCHAR2
                                  ,x_message                  OUT     VARCHAR2) IS

    ----------------------------------------------------------------------
    ---                Variable Declaration                            ---
    ----------------------------------------------------------------------

   EX_INVALID_PAYRUN            EXCEPTION;
   ln_responsibility_id         NUMBER;
   ln_application_id            NUMBER;
   ln_user_id                   NUMBER;
   ln_payrun_cnt                NUMBER;
   ln_status_cnt                NUMBER;
   ld_payment_date              DATE;
   ln_org_id                    NUMBER;
   lc_message                   VARCHAR(4000);
   lc_token                     VARCHAR(4000);

   BEGIN
   
    ----------------------------------------------------------------------
    ---                Apps Initialization                             ---
    ----------------------------------------------------------------------

      BEGIN
          SELECT  responsibility_id
                  ,application_id
            INTO  ln_responsibility_id
                  ,ln_application_id
            FROM  fnd_responsibility_tl
           WHERE  responsibility_name = p_resp_name   
             AND  language ='US';
     
          SELECT  user_id
            INTO  ln_user_id
            FROM  fnd_user
           WHERE  user_name = p_user_name; 

          fnd_global.apps_initialize (ln_user_id
                                      ,ln_responsibility_id
                                      ,ln_application_id
                                     );
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
           null;
      WHEN TOO_MANY_ROWS THEN
           null;
      END;
    
    ----------------------------------------------------------------------
    ---                Payrun validation                               ---
    -- If no records exist in the source staging table for the input    --
    -- payrun name,return Error and Invalid Payrun as the out message   --
    -- to the BPEL process. BPEL process will not proceed processing    --
    -- further.                                                         --
    ----------------------------------------------------------------------
     
      SELECT COUNT(record_id)
        INTO ln_payrun_cnt
        FROM xx_oic_payment_details_stg
       WHERE payrun_name = SUBSTR(p_payrun,1,INSTR(p_payrun,':')-1)
         AND operating_unit = SUBSTR(p_payrun,INSTR(p_payrun,':')+1);

      IF ln_payrun_cnt = 0 THEN
         RAISE EX_INVALID_PAYRUN;
      END IF;

    ----------------------------------------------------------------------
    ---     Insert / Update record in the audit history table          ---
    -- Check whether a record exist for the input payrun in the audit   --
    -- history table. If record do not exist, Insert a new record. If   --
    -- record already exist for the input payrun, then update existing  --
    -- record.                                                          --
    ----------------------------------------------------------------------

      SELECT COUNT(*)
        INTO ln_status_cnt
        FROM xx_oic_pay_status_history
       WHERE payrun = SUBSTR(p_payrun,1,INSTR(p_payrun,':')-1)
         AND operating_unit = SUBSTR(p_payrun,INSTR(p_payrun,':')+1);

      IF ln_status_cnt = 0 THEN
       
         BEGIN
             SELECT payment_date
	           ,org_id
               INTO ld_payment_date
	           ,ln_org_id
               FROM xx_oic_payment_details_stg
              WHERE payrun_name = SUBSTR(p_payrun,1,INSTR(p_payrun,':')-1)
                AND operating_unit = SUBSTR(p_payrun,INSTR(p_payrun,':')+1)
		AND ROWNUM < 2;

         EXCEPTION 
         WHEN NO_DATA_FOUND THEN
              NULL;
         END;

    ----------------------------------------------------------------------
    ---                Inserting Record                                ---
    -- Inserting a record in audit history table if the record for the  --
    -- input payrun and operating unit does not exist.                  --
    ----------------------------------------------------------------------

         INSERT INTO XX_OIC_PAY_STATUS_HISTORY(
          record_id
         ,payrun
         ,operating_unit
         ,org_id
	 ,payrun_date
         ,bpel_transfer_date
         ,transfer_status
         ,reason
         ,log
         ,created_by
         ,creation_date
         ,last_update_date
         ,last_updated_by
         ,last_updated_login) 
         VALUES(
          xx_oic_pay_status_history_s.NEXTVAL
         ,SUBSTR(p_payrun,1,INSTR(p_payrun,':')-1)
         ,SUBSTR(p_payrun,INSTR(p_payrun,':')+1)
         ,ln_org_id
	 ,ld_payment_date
         ,p_bpel_transfer_date
         ,p_transfer_status
         ,p_reason
         ,rawtohex(p_log)
         ,NVL(FND_GLOBAL.user_id,-1)
         ,SYSDATE
         ,SYSDATE
         ,nvl(FND_GLOBAL.user_id,-1)
         ,nvl(FND_GLOBAL.login_id,-1));
      ELSE

    ----------------------------------------------------------------------
    ---                Updating Record                                 ---
    -- Updating status in the audit history table                       --
    ----------------------------------------------------------------------

	UPDATE xx_oic_pay_status_history
           SET transfer_status    = p_transfer_status
              ,reason             = p_reason
              ,log                = RAWTOHEX(p_log)
              ,last_update_date   = sysdate
              ,last_updated_by    = nvl(FND_GLOBAL.user_id,-1)
              ,last_updated_login = nvl(FND_GLOBAL.login_id,-1)
         WHERE payrun         = SUBSTR(p_payrun,1,INSTR(p_payrun,':')-1)
           AND operating_unit = SUBSTR(p_payrun,INSTR(p_payrun,':')+1);
      END IF;

      COMMIT;
  EXCEPTION
  WHEN EX_INVALID_PAYRUN THEN
       x_status      := 'Error';
       x_message     :=  'Invalid Payrun';
       FND_MESSAGE.SET_NAME('XXCRM','XX_OIC_0029_INVALID_PAYRUN');
       lc_token      := SUBSTR(p_payrun,1,INSTR(p_payrun,':')-1);
       FND_MESSAGE.SET_TOKEN('MESSAGE', lc_token);
       lc_message    := FND_MESSAGE.GET;

       XX_COM_ERROR_LOG_PUB.log_error_crm
			( p_application_name        =>  'XXCRM'
			, p_program_type            =>  'I0607_IncentiveAndBonusToPayroll'
			, p_program_name            =>  'XX_OIC_BONUSTOPAYROLL_PKG'
			, p_module_name             =>  'OIC'
			, p_error_location          =>  'MAINTAIN_AUDIT_HISTORY'
			, p_error_message_code      =>  'XX_OIC_0029_INVALID_PAYRUN'
			, p_error_message           =>  lc_message
			, p_error_message_severity  =>  'MAJOR'
			);


  WHEN OTHERS THEN
       x_status      := 'Error';
       FND_MESSAGE.SET_NAME('XXCRM','XX_OIC_0030_BONUSPAY_ERROR');
       lc_token      := SQLCODE||':'||SQLERRM;
       FND_MESSAGE.SET_TOKEN('MESSAGE', lc_token);
       lc_message    := FND_MESSAGE.GET;
       x_message     :=  lc_message;
       XX_COM_ERROR_LOG_PUB.log_error_crm
			( p_application_name        =>  'XXCRM'
			, p_program_type            =>  'I0607_IncentiveAndBonusToPayroll'
			, p_program_name            =>  'XX_OIC_BONUSTOPAYROLL_PKG'
			, p_module_name             =>  'OIC'
			, p_error_location          =>  'MAINTAIN_AUDIT_HISTORY'
			, p_error_message_code      =>  'XX_OIC_0030_BONUSPAY_ERROR'
			, p_error_message           =>  SUBSTR(lc_message,1,4000)
			, p_error_message_severity  =>  'MAJOR'
			);

   
   END Maintain_Audit_History;

 
END XX_OIC_BONUSTOPAYROLL_PKG;
/
SHOW ERRORS;