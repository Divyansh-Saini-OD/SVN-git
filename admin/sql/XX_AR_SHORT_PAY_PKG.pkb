SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_AR_SHORT_PAY_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_AR_SHORT_PAY_PKG
AS
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |                       WIPRO Technologies                                  |
-- +===========================================================================+
-- | Name     :  Short Pay Workflow                                            |
-- | Rice id  :  E1326                                                         |
-- | Description : TO Identify the valid Short Paid Invoices and creating      |
-- |               a Task for the Research Team Member linked to a             |
-- |               Collector who is linked to the Customer                     |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date              Author              Remarks                    |
-- |======   ==========     =============        ============================= |
-- |1.0       28-JUN-2007   Chaitanya Nath.G      Initial version              |
-- |                       Wipro Technologies                                  |
-- |1.1       24-OCT-2007  Chaitanya Nath.G       Changed for the Defect :2409 |
-- |                                                                           |
-- |1.2       19-Mar-2008  Mohan,wipro            Modified to fix defect 4735  |
-- |1.3       19-jun-2008  Mohan, Wipro           to fix defect 8142           |
-- |1.4       04-AUG-2008  Ram                    Fix for Defect 9525          |
-- |1.5       26-SEP-2008  Aravind A.             Defect 11595,Performance     |
-- |                                              fixes                        |
-- |1.6       17-SEP-2009  Ganesan JV             Defect 2496,Added Hints      |
-- |1.7       05-MAY-2010  Poornimadevi R         Added  for Defect 4314       |
-- |1.8       23-APR-2012  Bapuji Nanapaneni      Added logic for Defect 17760 |
-- +===========================================================================+
-- +==========================================================================+
-- | Name : NOTIFY                                                            |
-- | Description :   TO Identify the valid Short Paid Invoices and creating   |
-- |                 a Task for the Research Team Member linked to a          |
-- |                 Collector who is linked to the Customer                  |
-- |                                                                          |
-- | Parameters :   p_receipt_date_from ,p_task_type,p_task_status,           |
-- |                p_owner_code, p_receipt_date_prior                        |
-- | Returns    :    x_error_buff,x_ret_code                                  |
-- +==========================================================================+
   PROCEDURE NOTIFY(
                    x_error_buff          OUT  VARCHAR2
                   ,x_ret_code            OUT  NUMBER
                   ,p_receipt_date_from   IN   DATE
                   ,p_task_type           IN   VARCHAR2
                   ,p_task_status         IN   VARCHAR2
                   ,p_owner_code          IN   VARCHAR2
                   ,p_receipt_date_prior  IN   DATE       -- Added for Defect 9525
                   )
   AS
      lc_cut_off                    ar_system_parameters.attribute7%TYPE;
      ln_task_status_id             jtf_task_statuses_b.task_status_id%TYPE;
      ld_request_date               fnd_concurrent_requests.request_date%TYPE;
      lc_concurrent_program_name    fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
      lc_default_drt                ar_system_parameters.attribute8%TYPE;
      ln_resource_id                jtf_rs_resource_extns_vl.resource_id%TYPE;
      ln_default_resource_id        jtf_rs_resource_extns_vl.resource_id%TYPE;
      ln_task_id                    jtf_tasks_vl.task_id%TYPE;
      ln_task_number                jtf_tasks_vl.task_number%TYPE;
      ln_user_name                  fnd_user.user_name%TYPE;
      lc_error_loc                  VARCHAR2(2000);
      lc_error_debug                VARCHAR2(2000);
      lc_loc_err_msg                VARCHAR2(2000);
      lcu_short_paid_invoices       VARCHAR2(2000);
      lc_description                VARCHAR2(2000);
      lc_task_type                  VARCHAR2(2000);
      lc_return_status              VARCHAR2(2000);
      lc_message_data               VARCHAR2(2000);
      lc_drt_found                  VARCHAR2(1):= 'Y';
      ln_message_count              NUMBER;
      ln_task_count                 NUMBER := 0;
      EX_CUT_OFF                    EXCEPTION;
      EX_TASK_STATUS                EXCEPTION;
      EX_TASK_TYPE                  EXCEPTION;
      EX_DEFAULT_DRT_MEMBER         EXCEPTION;
      lc_msg_data                   VARCHAR2(2000); -- defect 1688 
      /* defect 17760 */
      lc_activity_name              ar_receivables_trx_all.name%TYPE;
      ln_percentage                 NUMBER := 0;
      ln_remaining_due_amt          NUMBER := 0;
      ln_discount_amount            NUMBER := 0;
      ln_rec_trx_id                 NUMBER := 0;
      ln_adj_amount                 NUMBER := 0;
      ln_applied_amount             NUMBER := 0;
      ln_invoice_amount             NUMBER := 0;
      ln_amt_due_remaining          NUMBER := 0;
      ln_set_of_books_id            NUMBER;
      lr_inp_adj_rec                ar_adjustments%ROWTYPE;
      ln_adj_number                 VARCHAR2(30);
      ln_adj_id                     NUMBER;
      ln_adj_count                  NUMBER;
      
      CURSOR c_short_paid_invoices (
          p_receipt_date_from   DATE
      )IS
      SELECT     /*+ LEADING(ASP ARA RCT ACR) */ACR.receipt_date    -- Added by Ganesan for defect 2496
                ,ACR.receipt_number
                ,ARA.amount_applied 
                ,RCT.trx_number
                ,RCT.invoice_currency_code
                ,ACR.currency_code
                ,HCA.account_number
                ,HCA.cust_account_id
                ,SUM(RCTL.extended_amount) INVOICEAMOUNT
                ,AC.attribute6
                ,RCT.bill_to_site_use_id
                ,HP.party_name                  -- Added for the Defect ID : 2409
                ,HP.party_id                    -- Added for the Defect ID : 2409
                ,APS.acctd_amount_due_remaining -- Added for the Defect ID : 2409
                ,RTT.type class                 -- Added for the Defect ID : 17760 
                ,APS.payment_schedule_id        -- Added for the Defect ID : 17760 
                ,RCT.customer_trx_id            -- Added for the Defect ID : 17760
                ,TO_NUMBER(ASP.attribute7) flat_amount_val -- Added for the Defect ID : 17760
      FROM       ar_cash_receipts ACR
                ,ar_payment_schedules APS
                ,ar_receivable_applications ARA
                ,ra_customer_trx RCT
                ,ra_customer_trx_lines RCTL
                ,hz_cust_accounts HCA
                ,ar_system_parameters ASP
                ,ar_collectors AC
                ,hz_customer_profiles HCP
                ,hz_parties  HP
                ,ra_cust_trx_types_all RTT      -- Added for the Defect ID : 17760
      WHERE     -- TRUNC(ACR.creation_date) BETWEEN TRUNC(SYSDATE-2) AND TRUNC(SYSDATE)
                -- fix for 8142 TRUNC(ACR.creation_date) BETWEEN NVL(p_receipt_date_from,ld_request_date) AND TRUNC(SYSDATE-1)
		--Defect 11595, performance fix
                 --TRUNC(ARA.creation_date) BETWEEN NVL(p_receipt_date_from,ld_request_date) AND p_receipt_date_prior -- added for defect 8142
		 --ARA.creation_date BETWEEN NVL(p_receipt_date_from,ld_request_date) AND p_receipt_date_prior --Defect 11595 -- Commented for Defect#4314
                 ARA.creation_date BETWEEN NVL(p_receipt_date_from,ld_request_date) AND 
                 TO_DATE(TO_CHAR(TO_DATE(p_receipt_date_prior,'DD-MON-RRRR HH24:MI:SS'),'DD-MON-RRRR') || '23:59:59','DD-MON-RRRR HH24:MI:SS')-- Added for Defect#4314
      AND        ARA.status = 'APP'
   -- AND        ACR.status = 'APP' commented since this receipt was not getting picked when partial amount receipt is partially applied to invoice.
      AND        HCP.site_use_id IS  NULL
      AND        ARA.cash_receipt_id = ACR.cash_receipt_id
      AND        ARA.applied_customer_trx_id = RCT.customer_trx_id
      AND        RCT.cust_trx_type_id    = RTT.cust_trx_type_id
      AND        RCT.customer_trx_id = RCTL.customer_trx_id
      AND        APS.customer_id = HCA.cust_account_id
      AND        APS.customer_trx_id =RCT.customer_trx_id 
    --  AND        APS.acctd_amount_due_remaining > TO_NUMBER(ASP.attribute7) --defect 17760
      AND        APS.acctd_amount_due_remaining > 0 -- defect 17760
      AND        HCA.cust_account_id = HCP.cust_account_id
      AND        HCP.collector_id  = AC.collector_id 
      AND        HP.party_id = HCA.party_id
      AND        ARA.display ='Y'  -- added for fix defect 4735 which should not consider unapplied receipts.
      GROUP BY   ACR.receipt_date
                ,ACR.receipt_number
                ,ARA.amount_applied
                ,RCT.bill_to_site_use_id
                ,RCT.trx_number
                ,HCA.account_number
                ,HCA.cust_account_id
                ,HP.party_name                  -- Added for the Defect ID : 2409
                ,HP.party_id                    -- Added for the Defect ID : 2409
                ,APS.acctd_amount_due_remaining -- Added for the Defect ID : 2409
                ,AC.attribute6
                ,RCT.invoice_currency_code
                ,ACR.currency_code
                ,RTT.type                       -- Added for the Defect ID : 17760
                ,APS.payment_schedule_id        -- Added for the Defect ID : 17760
                ,RCT.customer_trx_id            -- Added for the Defect ID : 17760
                ,TO_NUMBER(ASP.attribute7);     -- Added for the Defect ID : 17760
   BEGIN

      --Printing the Parameters
      lc_error_loc   := 'Printing the Parameters of the program';
      lc_error_debug := '';
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Parameters');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'==============================================');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Receipt Date From  : ' ||p_receipt_date_from);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Task Type          : ' ||p_task_type);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Task Status        : ' ||p_task_status);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Owner type code    : ' ||p_owner_code);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Receipt Date Prior : ' ||p_receipt_date_prior);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'==============================================');
      --To Get the  Concurrent Program Name
      lc_error_loc   := 'Get the Concurrent Program Name:';
      lc_error_debug := 'Concurrent Program id: '||FND_GLOBAL.CONC_PROGRAM_ID;

      SELECT   user_concurrent_program_name
      INTO     lc_concurrent_program_name
      FROM     fnd_concurrent_programs_tl
      WHERE    concurrent_program_id = FND_GLOBAL.CONC_PROGRAM_ID
      AND      language = USERENV('LANG');
      
       --To Get the  Last Successfull Run Date of OD: AR Identify Short Pay
      BEGIN

      lc_error_loc   := 'Get the Last Successfull Run Date of the OD: AR Identify Short Pay';
      lc_error_debug := 'Phase code: C -- Status Code: C ';

         SELECT   --MAX(TRUNC(request_date))
                  MAX(actual_start_date)   -- Added for the Defect ID : 17760
         INTO     ld_request_date
         FROM     fnd_concurrent_requests
         WHERE    concurrent_program_id = FND_GLOBAL.CONC_PROGRAM_ID 
         AND      status_code = 'C'
         AND      phase_code  = 'C';

      EXCEPTION

      WHEN NO_DATA_FOUND THEN
         FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0002_CONC_PROGRAM_ERROR');
         lc_loc_err_msg :=  FND_MESSAGE.GET;
         FND_FILE.PUT_LINE(FND_FILE.LOG,lc_loc_err_msg);

      WHEN OTHERS THEN
         FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0001_ERROR ');
         FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
         FND_MESSAGE.SET_TOKEN('ERR_DEBUG',lc_error_debug);
         FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
         lc_loc_err_msg :=  FND_MESSAGE.GET;
         FND_FILE.PUT_LINE(FND_FILE.LOG,lc_loc_err_msg);
         XX_COM_ERROR_LOG_PUB.LOG_ERROR (
            p_program_type            => 'CONCURRENT PROGRAM'
           ,p_program_name            => lc_concurrent_program_name
           ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
           ,p_module_name             => 'AR'
           ,p_error_location          => 'Error at ' || lc_error_loc
           ,p_error_message_count     => 1
           ,p_error_message_code      => 'E'
           ,p_error_message           => lc_loc_err_msg
           ,p_error_message_severity  => 'Major'
           ,p_notify_flag             => 'N'
           ,p_object_type             => 'Short Pay'
                                        );
      END;
      
         -- To Get the short paid cut off amount and default drt user  into local variable
      BEGIN
         lc_error_loc   := 'Get the System Short Pay cut off Amount and default DRT member.';
         lc_error_debug := '';
         SELECT   attribute7
                 ,attribute8
         INTO     lc_cut_off
                 ,lc_default_drt
         FROM     ar_system_parameters;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RAISE EX_CUT_OFF;
      END;
         -- To Get the status id of the task
      BEGIN
         lc_error_loc   := 'Get the Status id of the Task: ';
         lc_error_debug := ' Task status : '||p_task_status;
         SELECT   JB.task_status_id 
         INTO     ln_task_status_id
         FROM     jtf_task_statuses_b JB 
                 ,jtf_task_statuses_tl JT
         WHERE    JB.task_status_id = JT.task_status_id
         AND      UPPER(JT.name) = UPPER(p_task_status);
      EXCEPTION
      WHEN NO_DATA_FOUND THEN 
         RAISE EX_TASK_STATUS;
      END;
          -- To Get the Task Type into local variable.
       BEGIN
         lc_error_loc   := 'Get the Task Type';
         lc_error_debug := 'Task Type :'||p_task_type;
          SELECT   name 
          INTO     lc_task_type
          FROM     jtf_task_types_tl
          WHERE    name = p_task_type;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN 
         RAISE EX_TASK_TYPE;
      END;
          -- To  validate default DRT member and validate.
      BEGIN
         lc_error_loc   := 'Get the default DRT member';
         lc_error_debug := '';
            SELECT   JRRE.resource_id
            INTO     ln_default_resource_id
            FROM     jtf_rs_resource_extns_vl JRRE
                    ,fnd_user FU
            WHERE    FU.user_id=JRRE.user_id
            AND      TRUNC(NVL(JRRE.end_date_active,SYSDATE+1)) > TRUNC(SYSDATE)
            AND      TRUNC(NVL(FU.end_date,SYSDATE+1)) > TRUNC(SYSDATE)
            AND      FU.user_name = lc_default_drt;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN 
         RAISE EX_DEFAULT_DRT_MEMBER;
      END;

      FOR lcu_short_paid_invoices IN c_short_paid_invoices (p_receipt_date_from)
      LOOP
         lc_description := NULL;
         ln_resource_id := NULL;
         lc_drt_found   := 'Y';
         ln_task_count  := 0;
         ln_task_number := NULL;
         ln_user_name   := NULL;
         
         /**************************************DEFECT 17760 BEGIN************************************************/
         -- Need to check for CM

         /* Added Logic to create Adjustments for flat discount customers --NB */
         
         IF lcu_short_paid_invoices.class = 'CM' THEN
             ln_applied_amount    := (-1*lcu_short_paid_invoices.amount_applied);
             ln_invoice_amount    := (-1*lcu_short_paid_invoices.invoiceamount);
             ln_amt_due_remaining := (-1*lcu_short_paid_invoices.acctd_amount_due_remaining);
             
         ELSE
             ln_applied_amount    := lcu_short_paid_invoices.amount_applied;
             ln_invoice_amount    := lcu_short_paid_invoices.invoiceamount;
             ln_amt_due_remaining := lcu_short_paid_invoices.acctd_amount_due_remaining;
         END IF;
	 
	 IF ln_applied_amount < ln_invoice_amount THEN
	     validate_dis_cust( p_customer_number => lcu_short_paid_invoices.account_number
	                      , x_activity_name   => lc_activity_name
	                      , x_dis_percentage  => ln_percentage
	                      );
	     IF ln_percentage > 0 THEN
	         ln_discount_amount := ROUND(((ln_invoice_amount * ln_percentage)/100),2);
	         IF ln_amt_due_remaining <= ln_discount_amount THEN
	             ln_adj_amount        := ln_amt_due_remaining;
	             ln_remaining_due_amt := 0;
	         ELSE
	             ln_adj_amount        := ln_discount_amount;
	             ln_remaining_due_amt := (ln_amt_due_remaining - ln_discount_amount);
	             
	         END IF;
	         
	         --Create Auto Adjustment
	         /* Activity Name */
                 SELECT receivables_trx_id
                   INTO ln_rec_trx_id
                   FROM ar_receivables_trx_all
                  WHERE UPPER(NAME) = UPPER(lc_activity_name);
                  
                  SELECT COUNT(*)
                    INTO ln_adj_count
                    FROM ar_adjustments_all
                   WHERE customer_trx_id    = lcu_short_paid_invoices.customer_trx_id
                     AND receivables_trx_id = ln_rec_trx_id;

                 IF ln_adj_count > 0 THEN
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'Discount Already Applied Before For Invoice No  : ' ||lcu_short_paid_invoices.trx_number);
                     GOTO END_OF_LOOP_CALL;
                 END IF;
                 
                 /* Set of Books id */
                 ln_set_of_books_id := fnd_profile.value('GL_SET_OF_BKS_ID');
                 
                 IF lcu_short_paid_invoices.class = 'INV' THEN 
                     lr_inp_adj_rec.acctd_amount         := (-1 * ln_adj_amount);
                     lr_inp_adj_rec.amount               := (-1 * ln_adj_amount);
                 ELSE
                     lr_inp_adj_rec.acctd_amount         := ln_adj_amount;
                     lr_inp_adj_rec.amount               := ln_adj_amount;
                 END IF;
                 
                 lr_inp_adj_rec.adjustment_id        := NULL;
                 lr_inp_adj_rec.adjustment_number    := NULL;
                 lr_inp_adj_rec.adjustment_type      := 'M'; 
                 lr_inp_adj_rec.created_by           := FND_GLOBAL.USER_ID;
                 lr_inp_adj_rec.created_from         := 'XX_AR_SHORT_PAY_PKG_NOTIFY';
                 lr_inp_adj_rec.creation_date        := SYSDATE;
                 lr_inp_adj_rec.gl_date              := SYSDATE;
                 lr_inp_adj_rec.last_update_date     := SYSDATE;
                 lr_inp_adj_rec.last_updated_by      := FND_GLOBAL.USER_ID;
                 lr_inp_adj_rec.posting_control_id   := -3;         /* -1,-2,-4 for posted in previous rel and -3 for not posted */
                 lr_inp_adj_rec.set_of_books_id      := ln_set_of_books_id;		
                 lr_inp_adj_rec.status               := 'A';
                 lr_inp_adj_rec.type                 := 'LINE';     /* ADJ TYPE CHARGES,FREIGHT,INVOICE,LINE,TAX */
                 lr_inp_adj_rec.payment_schedule_id  := lcu_short_paid_invoices.payment_schedule_id;   
                 lr_inp_adj_rec.apply_date           := SYSDATE;
                 lr_inp_adj_rec.receivables_trx_id   := ln_rec_trx_id;   
                 lr_inp_adj_rec.customer_trx_id      := lcu_short_paid_invoices.customer_trx_id; 
                 lr_inp_adj_rec.comments             := 'FLAT DISCOUNT';
                 lr_inp_adj_rec.reason_code          := 'DISCOUNT';

                 ar_adjust_pub.create_adjustment ( p_api_name             => 'XX_AR_WC_AR_INBOUND_PKG'
                                                 , p_api_version          => 1.0
                                                 , p_init_msg_list        => FND_API.G_TRUE
                                                 , p_commit_flag          => FND_API.G_TRUE
                                                 , p_validation_level     => FND_API.G_VALID_LEVEL_FULL
                                                 , p_msg_count            => ln_message_count
                                                 , p_msg_data             => lc_message_data
                                                 , p_return_status        => lc_return_status
                                                 , p_adj_rec              => lr_inp_adj_rec
                                                 , p_chk_approval_limits  => NULL
                                                 , p_check_amount         => NULL
                                                 , p_move_deferred_tax    => 'Y'
                                                 , p_new_adjust_number    => ln_adj_number
                                                 , p_new_adjust_id        => ln_adj_id
                                                 , p_called_from          => NULL
                                                 , p_old_adjust_id        => NULL
                                                 );
                 IF lc_return_status != 'S' OR ln_remaining_due_amt <= NVL(lcu_short_paid_invoices.flat_amount_val,0) THEN
                     IF ln_message_count >= 1 THEN
                         FOR I IN 1..ln_message_count LOOP
                             FND_FILE.PUT_LINE(FND_FILE.LOG, 'lc_message_data : '|| lc_message_data);
                             FND_FILE.PUT_LINE(FND_FILE.LOG,(I||'. '||SUBSTR(FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE ), 1, 255)));
                             IF i = 1 THEN
                                 lc_message_data := I||'. '||SUBSTR(FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE ), 1, 255);
                             END IF;
                         END LOOP;
                     END IF;
                     IF lc_return_status = 'S' THEN
                         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Remaining Amount : '||ln_remaining_due_amt ||' Is less Then : '|| lcu_short_paid_invoices.flat_amount_val);
                     END IF;
                     GOTO END_OF_LOOP_CALL;
                 ELSE
                     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'------------------------------------');
                     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Auto Adjustment is created aganist AdjustmentID : '|| ln_adj_id);
                     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Invoice Number    : '||lcu_short_paid_invoices.trx_number);
                     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Adjustment Number : '||ln_adj_number);
                     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'------------------------------------');
                 END IF;
	     END IF;
         END IF;
         /**************************************DEFECT 17760 END************************************************/
         
         IF (lcu_short_paid_invoices.attribute6) IS NOT NULL THEN 
            -- To Get the resource id of the DRT member and also validating the DRT member.
            BEGIN
               lc_error_loc   := 'To Get the DRT resource id and also  to verify if he is a FND user ';
               lc_error_debug := ' DRT User :'||lcu_short_paid_invoices.attribute6;
               SELECT   JRRE.resource_id
               INTO     ln_resource_id
               FROM     jtf_rs_resource_extns_vl JRRE
                       ,fnd_user FU
               WHERE    FU.user_id=JRRE.user_id
               AND      FU.user_name = lcu_short_paid_invoices.attribute6
               AND      TRUNC(NVL(JRRE.end_date_active,SYSDATE+1)) > TRUNC(SYSDATE)
               AND      TRUNC(NVL(FU.end_date,SYSDATE+1)) > TRUNC(SYSDATE);
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
               FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0007_DEFAULT_DRT');
               FND_MESSAGE.SET_TOKEN('DRT_MEM',lcu_short_paid_invoices.attribute6);
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,FND_MESSAGE.GET);
               ln_resource_id := ln_default_resource_id;
               lcu_short_paid_invoices.attribute6:= lc_default_drt;
               lc_drt_found := 'N';
            END;
         ELSE -- No Colletor found
            ln_resource_id := ln_default_resource_id;
            lcu_short_paid_invoices.attribute6:= lc_default_drt;
            FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0008_DEFAULT_DRT');
            FND_MESSAGE.SET_TOKEN('DEF_DRT',lc_default_drt);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,FND_MESSAGE.GET);
            lc_drt_found := 'D';
         END IF;
         IF lc_drt_found  = 'Y' THEN
                 -- This is used for the description parameter for the api
            lc_description :=   ' Account Number - '||lcu_short_paid_invoices.account_number
                              ||' Customer Name '||lcu_short_paid_invoices.party_name
                              ||' Receipt Date - '  ||lcu_short_paid_invoices.receipt_date
                              ||' Receipt Number - '||lcu_short_paid_invoices.receipt_number
                              ||' Amount Applied - '||'$'||lcu_short_paid_invoices.amount_applied||' '||lcu_short_paid_invoices.currency_code
                              ||' Invoice Number - '||lcu_short_paid_invoices.trx_number
                              ||' Invoice Amount - '||'$'||lcu_short_paid_invoices.INVOICEAMOUNT||' '||lcu_short_paid_invoices.invoice_currency_code;
         ELSIF lc_drt_found  = 'N' THEN 
               -- This is used for the description parameter for the api
            lc_description :=  'The DRT member is not valid so the task is assigned to default DRT member : '|| lc_default_drt
                              ||' Account Number - '||lcu_short_paid_invoices.account_number
                              ||' Customer Name '||lcu_short_paid_invoices.party_name
                              ||' Receipt Date - '  ||lcu_short_paid_invoices.receipt_date
                              ||' Receipt Number - '||lcu_short_paid_invoices.receipt_number
                              ||' Amount Applied - '||'$'||lcu_short_paid_invoices.amount_applied||' '||lcu_short_paid_invoices.currency_code
                              ||' Invoice Number - '||lcu_short_paid_invoices.trx_number
                              ||' Invoice Amount - '||'$'||lcu_short_paid_invoices.INVOICEAMOUNT||' '||lcu_short_paid_invoices.invoice_currency_code;
         ELSE 
               -- This is used for the description parameter for the api
            lc_description :=  'Collector is not defined for the customer so the task is assigned to default DRT member : '|| lc_default_drt
                              ||' Account Number - '||lcu_short_paid_invoices.account_number
                              ||' Customer Name '||lcu_short_paid_invoices.party_name
                              ||' Receipt Date - '  ||lcu_short_paid_invoices.receipt_date
                              ||' Receipt Number - '||lcu_short_paid_invoices.receipt_number
                              ||' Amount Applied - '||'$'||lcu_short_paid_invoices.amount_applied||' '||lcu_short_paid_invoices.currency_code
                              ||' Invoice Number - '||lcu_short_paid_invoices.trx_number
                              ||' Invoice Amount - '||'$'||lcu_short_paid_invoices.INVOICEAMOUNT||' '||lcu_short_paid_invoices.invoice_currency_code;
         END IF;
          -- To Assign a Task 
         BEGIN
            -- Verify whether task is already created for the transaction
            -- Added  for Defect 9525
            lc_error_loc := 'Assigning a task for the short paid invoice to the DRT member';
            lc_error_debug := ' Invoice Number - '||lcu_short_paid_invoices.trx_number;
            SELECT   COUNT(1)
            INTO     ln_task_count 
            FROM     jtf_tasks_v
            WHERE    task_name  = lcu_short_paid_invoices.trx_number
            --AND      costs      = lcu_short_paid_invoices.acctd_amount_due_remaining; 
            AND      costs      = ln_remaining_due_amt;  -- Added for the Defect ID : 17760
            IF (ln_task_count > 0) THEN
           -- Get the details of the task which is already created
           -- Added  for Defect 9525
               SELECT   JTFT.task_number
                       ,FU.user_name
               INTO     ln_task_number
                       ,ln_user_name
               FROM     jtf_tasks_v JTFT
                       ,jtf_rs_resource_extns_vl JRRE
                       ,fnd_user FU
               WHERE    task_name     = lcu_short_paid_invoices.trx_number
              -- AND      costs         = lcu_short_paid_invoices.acctd_amount_due_remaining
               AND      costs         = ln_remaining_due_amt  -- Added for the Defect ID : 17760
               AND      JTFT.owner_id = JRRE.resource_id
               AND      FU.user_id    = JRRE.user_id;
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'------------------------------------');
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Short Pay Task is already created for this transaction and assigned to '||ln_user_name);
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Invoice Number    : '||lcu_short_paid_invoices.trx_number);
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Task Number       : '||ln_task_number);
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'------------------------------------');
            ELSE
               JTF_TASKS_PUB.CREATE_TASK(
                  p_api_version               =>   '1.0'
                 ,p_init_msg_list             =>   fnd_api.g_true
                 ,p_commit                    =>   fnd_api.g_true
                 ,p_task_name                 =>   lcu_short_paid_invoices.trx_number
                 ,p_task_type_name            =>   lc_task_type
                 ,p_description               =>   lc_description
                 ,p_task_status_id            =>   ln_task_status_id
                 ,p_task_type_id              =>   NULL
                 ,p_owner_type_code           =>   p_owner_code
                 ,p_owner_id                  =>   ln_resource_id
                 ,p_source_object_type_code   =>   'IEX_BILLTO'
                 ,p_source_object_id          =>   lcu_short_paid_invoices.bill_to_site_use_id
                 ,p_source_object_name        =>   NULL
                 ,p_cust_account_id           =>   lcu_short_paid_invoices.cust_account_id -- Additions for the Defect ID : 2409
                 ,p_customer_id               =>   lcu_short_paid_invoices.party_id
                 --,p_costs                     =>   lcu_short_paid_invoices.acctd_amount_due_remaining
                 ,p_costs                     =>   ln_remaining_due_amt  -- Added for the Defect ID : 17760
                 ,p_currency_code             =>   lcu_short_paid_invoices.currency_code
                 ,p_cust_account_number       =>   lcu_short_paid_invoices.account_number -- End of additions for the Defect ID : 2409
                 ,x_return_status             =>   lc_return_status
                 ,x_msg_count                 =>   ln_message_count
                 ,x_msg_data                  =>   lc_message_data
                 ,x_task_id                   =>   ln_task_id
                                          );
              IF ( ln_task_id IS NOT NULL ) THEN 
                 -- To get the task number.
                 BEGIN
                    lc_error_loc   := 'To Get the task number ';
                    lc_error_debug := ' TASK ID :'||ln_task_id;
                    SELECT task_number
                    INTO   ln_task_number
                    FROM   jtf_tasks_vl
                    WHERE  task_id = ln_task_id;
                 EXCEPTION
                 WHEN NO_DATA_FOUND THEN 
                   FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0001_ERROR');
                   FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
                   FND_MESSAGE.SET_TOKEN('ERR_DEBUG',lc_error_debug);
                   FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
                   lc_loc_err_msg :=  FND_MESSAGE.GET;
                   FND_FILE.PUT_LINE(FND_FILE.LOG,lc_loc_err_msg);
                   XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                       p_program_type            => 'CONCURRENT PROGRAM'
                      ,p_program_name            => lc_concurrent_program_name
                      ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                      ,p_module_name             => 'AR'
                      ,p_error_location          => 'Error at ' || lc_error_loc
                      ,p_error_message_count     => 1
                      ,p_error_message_code      => 'E'
                      ,p_error_message           => lc_loc_err_msg
                      ,p_error_message_severity  => 'Major'
                      ,p_notify_flag             => 'N'
                      ,p_object_type             => 'Short Pay'
                                                    );
                 END;
                  FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0009_TASK_ASSIGNED');
                  FND_MESSAGE.SET_TOKEN('INV_NUM',lcu_short_paid_invoices.trx_number);
                  FND_MESSAGE.SET_TOKEN('DRT_MEMBER',lcu_short_paid_invoices.attribute6);
                  FND_MESSAGE.SET_TOKEN('TASK_TYPE',lc_task_type);
                  FND_MESSAGE.SET_TOKEN('TASK_NUM',ln_task_number);
                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,FND_MESSAGE.GET);
              ELSE 
	         -- added for defect 1688
	         IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
		    IF ln_message_count > 0 THEN
		       lc_msg_data := null;
		       FOR i IN 1..ln_message_count
		       LOOP
			  lc_msg_data := lc_msg_data||' '||FND_MSG_PUB.GET(1,'F');
                       END LOOP;
		       FND_MESSAGE.SET_ENCODED (lc_msg_data);
                       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
                       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'---------------------------------');
                       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,('Invoice number: '||lcu_short_paid_invoices.trx_number||' NO SHORT PAY CREATED FOR REASON: '||lc_msg_data));
                       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'---------------------------------');
                       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
                    END IF;
                 END IF;
              END IF;
              
            END IF; -- Count ln_task_count
            
         EXCEPTION
         WHEN  OTHERS THEN 
                FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0001_ERROR ');
                FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
                FND_MESSAGE.SET_TOKEN('ERR_DEBUG',lc_error_debug);
                FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
                lc_loc_err_msg :=  FND_MESSAGE.GET;
                FND_FILE.PUT_LINE(FND_FILE.LOG,lc_loc_err_msg);
                XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                   p_program_type            => 'CONCURRENT PROGRAM'
                  ,p_program_name            => lc_concurrent_program_name
                  ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                  ,p_module_name             => 'AR'
                  ,p_error_location          => 'Error at ' || lc_error_loc
                  ,p_error_message_count     => 1
                  ,p_error_message_code      => 'E'
                  ,p_error_message           => lc_loc_err_msg
                  ,p_error_message_severity  => 'Major'
                  ,p_notify_flag             => 'N'
                  ,p_object_type             => 'Short Pay'
                                                );
         END;
         <<END_OF_LOOP_CALL>>
         COMMIT;
      END LOOP;
   EXCEPTION
   WHEN EX_DEFAULT_DRT_MEMBER THEN
      FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0006_DRT_NOT_VALID');
      FND_MESSAGE.SET_TOKEN('DRT',lc_default_drt);
      lc_loc_err_msg :=  FND_MESSAGE.GET;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'==============================================');
      FND_FILE.PUT_LINE(FND_FILE.LOG,lc_loc_err_msg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'============================================== ');
      x_ret_code:= 2 ;
      XX_COM_ERROR_LOG_PUB.LOG_ERROR (
         p_program_type            => 'CONCURRENT PROGRAM'
        ,p_program_name            => lc_concurrent_program_name
        ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
        ,p_module_name             => 'AR'
        ,p_error_location          => 'Error at ' || lc_error_loc
        ,p_error_message_count     => 1
        ,p_error_message_code      => 'E'
        ,p_error_message           => lc_loc_err_msg
        ,p_error_message_severity  => 'Major'
        ,p_notify_flag             => 'N'
        ,p_object_type             => 'Short Pay'
                                      );
   WHEN EX_CUT_OFF THEN
      FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0003_CUTOFF_NOT_SETUP');
      lc_loc_err_msg :=  FND_MESSAGE.GET;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'==============================================');
      FND_FILE.PUT_LINE(FND_FILE.LOG,lc_loc_err_msg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'============================================== ');
      x_ret_code:= 2 ;
      XX_COM_ERROR_LOG_PUB.LOG_ERROR (
         p_program_type            => 'CONCURRENT PROGRAM'
        ,p_program_name            => lc_concurrent_program_name
        ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
        ,p_module_name             => 'AR'
        ,p_error_location          => 'Error at ' || lc_error_loc
        ,p_error_message_count     => 1
        ,p_error_message_code      => 'E'
        ,p_error_message           => lc_loc_err_msg
        ,p_error_message_severity  => 'Major'
        ,p_notify_flag             => 'N'
        ,p_object_type             => 'Short Pay'
                                      );
   WHEN EX_TASK_STATUS THEN
      FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0004_TASK_STATUS_NOT_SET');
      FND_MESSAGE.SET_TOKEN('TASK_STATUS',p_task_status);
      lc_loc_err_msg :=  FND_MESSAGE.GET;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'==============================================');
      FND_FILE.PUT_LINE(FND_FILE.LOG,lc_loc_err_msg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'============================================== ');
      x_ret_code:= 2 ;
      XX_COM_ERROR_LOG_PUB.LOG_ERROR (
         p_program_type            => 'CONCURRENT PROGRAM'
        ,p_program_name            => lc_concurrent_program_name
        ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
        ,p_module_name             => 'AR'
        ,p_error_location          => 'Error at ' || lc_error_loc
        ,p_error_message_count     => 1
        ,p_error_message_code      => 'E'
        ,p_error_message           => lc_loc_err_msg
        ,p_error_message_severity  => 'Major'
        ,p_notify_flag             => 'N'
        ,p_object_type             => 'Short Pay'
                                      );
   WHEN EX_TASK_TYPE THEN
      FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0005_TASK_NOT_DEFINED');
      FND_MESSAGE.SET_TOKEN('TASK_TYPE',lc_task_type);
      lc_loc_err_msg :=  FND_MESSAGE.GET;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'==============================================');
      FND_FILE.PUT_LINE(FND_FILE.LOG,lc_loc_err_msg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'============================================== ');
      x_ret_code:= 2 ;
      XX_COM_ERROR_LOG_PUB.LOG_ERROR (
         p_program_type            => 'CONCURRENT PROGRAM'
        ,p_program_name            => lc_concurrent_program_name
        ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
        ,p_module_name             => 'AR'
        ,p_error_location          => 'Error at ' || lc_error_loc
        ,p_error_message_count     => 1
        ,p_error_message_code      => 'E'
        ,p_error_message           => lc_loc_err_msg
        ,p_error_message_severity  => 'Major'
        ,p_notify_flag             => 'N'
        ,p_object_type             => 'Short Pay'
                                      );
   WHEN  OTHERS THEN 
      FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0001_ERROR ');
      FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
      FND_MESSAGE.SET_TOKEN('ERR_DEBUG',lc_error_debug);
      FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
      lc_loc_err_msg :=  FND_MESSAGE.GET;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'==============================================');
      FND_FILE.PUT_LINE(FND_FILE.LOG,lc_loc_err_msg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'============================================== ');
      x_ret_code:= 2 ;
      XX_COM_ERROR_LOG_PUB.LOG_ERROR (
         p_program_type            => 'CONCURRENT PROGRAM'
        ,p_program_name            => lc_concurrent_program_name
        ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
        ,p_module_name             => 'AR'
        ,p_error_location          => 'Error at ' || lc_error_loc
        ,p_error_message_count     => 1
        ,p_error_message_code      => 'E'
        ,p_error_message           => lc_loc_err_msg
        ,p_error_message_severity  => 'Major'
        ,p_notify_flag             => 'N'
        ,p_object_type             => 'Short Pay'
                                      );
   END NOTIFY;
   
PROCEDURE VALIDATE_DIS_CUST( p_customer_number  IN  VARCHAR2
                           , x_activity_name    OUT VARCHAR2
                           , x_dis_percentage   OUT NUMBER
                           ) IS
                           
lc_activity_name     ar_receivables_trx_all.name%TYPE;
ln_percentage        NUMBER;
lc_error_loc         VARCHAR2(2000);
lc_error_debug       VARCHAR2(2000);
lc_loc_err_msg       xx_com_error_log.error_message%TYPE;
lc_concurrent_program_name fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;

BEGIN
    lc_error_loc   := 'To Get Customer Flat Discount Percentage ';
    lc_error_debug := ' CUSTOMER NUMBER :'||p_customer_number;
   
    SELECT user_concurrent_program_name
      INTO lc_concurrent_program_name
      FROM fnd_concurrent_programs_tl
     WHERE concurrent_program_id = FND_GLOBAL.CONC_PROGRAM_ID
       AND language = USERENV('LANG');
      
    SELECT xftv.target_value1 percentage
         , xftv.target_value2 activate_name
      INTO ln_percentage
         , lc_activity_name
      FROM xx_fin_translatedefinition xftd
         , xx_fin_translatevalues xftv
     WHERE xftd.translate_id              = xftv.translate_id
       AND xftd.translation_name          = 'FLAT_DISCOUNTS'
       AND xftv.source_value1             = p_customer_number
       AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
       AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
       AND XFTV.ENABLED_FLAG              = 'Y'
       AND xftd.enabled_flag              = 'Y';
       
       x_activity_name  := lc_activity_name;
       x_dis_percentage := ln_percentage;
       
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Flat Discount Customer Is : '|| p_customer_number);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Activite Name Is          : '|| lc_activity_name);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Discount Percentage       : '|| ln_percentage);
       

EXCEPTION

    WHEN NO_DATA_FOUND THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Not a Flat Discount Customer : '|| p_customer_number);
        x_dis_percentage    := 0;
        x_activity_name     := NULL;
        
    WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others Raised deriving flat discount : '||SQLERRM);
        FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0001_ERROR ');
        FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
        FND_MESSAGE.SET_TOKEN('ERR_DEBUG',lc_error_debug);
        FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
        lc_loc_err_msg :=  FND_MESSAGE.GET;
        FND_FILE.PUT_LINE(FND_FILE.LOG,lc_loc_err_msg);
        XX_COM_ERROR_LOG_PUB.LOG_ERROR ( p_program_type            => 'CONCURRENT PROGRAM'
                                       , p_program_name            => lc_concurrent_program_name
                                       , p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                       , p_module_name             => 'AR'
                                       , p_error_location          => 'Error at ' || lc_error_loc
                                       , p_error_message_count     => 1
                                       , p_error_message_code      => 'E'
                                       , p_error_message           => lc_loc_err_msg
                                       , p_error_message_severity  => 'Major'
                                       , p_notify_flag             => 'N'
                                       , p_object_type             => 'Short Pay'
                                       );
        x_dis_percentage := 0;
        x_activity_name  := NULL;
        
END VALIDATE_DIS_CUST;            

END XX_AR_SHORT_PAY_PKG;
/

SHO ERR