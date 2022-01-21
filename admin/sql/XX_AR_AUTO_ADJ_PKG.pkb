SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_AR_AUTO_ADJ_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE
 CREATE OR REPLACE PACKAGE BODY APPS.XX_AR_AUTO_ADJ_PKG AS 
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |  Providge Consulting                                                                       |
-- +============================================================================================+
-- |  Name:  XX_AR_AUTO_ADJ_PKG                                                                 |
-- |  Description:  This package creates and approves adjustments using the API AR_ADJUST_PUB   |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author               Remarks                                      |
-- | =========   ===========  =============        =============================================|
-- | 1.0         13-Aug-2010  Sneha Anand          Initial Version                              |
-- +============================================================================================+


    GB_DEBUG                   BOOLEAN         DEFAULT TRUE;  -- print debug/log output
    GN_RETURN_CODE             NUMBER          DEFAULT 0;     -- master program conc status
    GD_PROGRAM_RUN_DATE        DATE            DEFAULT SYSDATE; -- get the current date when first used

-- +============================================================================================+ 
-- |  Name: SET_DEBUG                                                                           | 
-- |  Description: This procedure turns on/off the debug mode.                                  |
-- |                                                                                            | 
-- |  Parameters:  p_debug - Debug Mode: TRUE=On, FALSE=Off                                     |
-- |                                                                                            | 
-- |  Returns:     N/A                                                                          |
-- +============================================================================================+
 PROCEDURE set_debug
 ( p_debug      IN      BOOLEAN       DEFAULT TRUE )
 IS
 BEGIN
    GB_DEBUG := p_debug;
 END;

-- +============================================================================================+ 
-- |  Name: GET_DEBUG_CHAR                                                                      | 
-- |  Description: This function to change debug to char (FND_API type.                         |
-- |                                                                                            | 
-- |  Parameters:  GB_DEBUG                                                                     |
-- |                                                                                            | 
-- |  Returns:     N/A                                                                          |
-- +============================================================================================+
 FUNCTION get_debug_char
 RETURN VARCHAR2
 IS
 BEGIN
    IF (GB_DEBUG) THEN
      RETURN FND_API.G_TRUE;
    ELSE
      RETURN FND_API.G_FALSE;
    END IF;
 END;

-- +============================================================================================+ 
-- |  Name: PUT_OUT_LINE                                                                        | 
-- |  Description: This procedure to print the output                                           |
-- |                                                                                            | 
-- |  Parameters:  p_buffer                                                                     |
-- |                                                                                            | 
-- |  Returns:     N/A                                                                          |
-- +============================================================================================+
 PROCEDURE put_out_line
 ( p_buffer     IN      VARCHAR2      DEFAULT ' ' )
 IS
 BEGIN
  -- if in concurrent program, print to output file
    IF (FND_GLOBAL.CONC_REQUEST_ID > 0) THEN
      FND_FILE.put_line(FND_FILE.OUTPUT,NVL(p_buffer,' '));
   -- else print to DBMS_OUTPUT
    ELSE
      DBMS_OUTPUT.put_line(SUBSTR(NVL(p_buffer,' '),1,255));
    END IF;
 END;


-- +============================================================================================+ 
-- |  Name: PUT_LOG_LINE                                                                        | 
-- |  Description: This procedure to print the log                                              |
-- |                                                                                            | 
-- |  Parameters:  p_buffer,p_force                                                             |
-- |                                                                                            | 
-- |  Returns:     N/A                                                                          |
-- +============================================================================================+

 PROCEDURE put_log_line
 ( p_buffer     IN      VARCHAR2      DEFAULT ' ',
   p_force      IN      BOOLEAN       DEFAULT FALSE 
  )
 IS
 BEGIN
   --if debug is on (defaults to true)
    IF (GB_DEBUG OR p_force) THEN
      -- if in concurrent program, print to log file
      IF (FND_GLOBAL.CONC_REQUEST_ID > 0) THEN
        FND_FILE.put_line(FND_FILE.LOG,NVL(TO_CHAR(SYSTIMESTAMP,'HH24:MI:SS.FF: ') || p_buffer,' '));
      -- else print to DBMS_OUTPUT
      ELSE
        DBMS_OUTPUT.put_line(SUBSTR(NVL(p_buffer,' '),1,255));
      END IF;
    END IF;
 END;

-- +============================================================================================+ 
-- |  Name: PUT_CURRENT_DATETIME                                                                | 
-- |  Description: This procedure for printing to the log the current datetime                  |
-- |                                                                                            | 
-- |  Parameters:  p_buffer                                                                     |
-- |                                                                                            | 
-- |  Returns:     N/A                                                                          |
-- +============================================================================================+

 PROCEDURE put_current_datetime
 ( p_buffer     IN      VARCHAR2      DEFAULT ' ' )
 IS
 BEGIN
    NULL;
    put_log_line('== ' || TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS') || ' ==');
 END;

-- +============================================================================================+ 
-- |  Name: PUT_CURRENT_DATETIME                                                                | 
-- |  Description: This procedure determines  Adjustment child batch size (based on the params) |
-- |                                                                                            | 
-- |  Parameters:  p_number_of_batches, p_record_count, x_new_num_of_batches, x_batch_size      |
-- |                                                                                            | 
-- |  Returns:     N/A                                                                          |
-- +============================================================================================+

 PROCEDURE get_batch_size
 ( p_number_of_batches      IN      NUMBER
  ,p_record_count           IN      NUMBER
  ,x_new_num_of_batches     OUT     NUMBER
  ,x_batch_size             OUT     NUMBER 
 )
 IS
  ln_new_num_of_batches       NUMBER       DEFAULT NULL;
  ln_batch_size               NUMBER       DEFAULT NULL;
 BEGIN
    IF (p_number_of_batches > p_record_count) THEN
       ln_new_num_of_batches := p_record_count;
       IF (GB_DEBUG) THEN
          put_log_line('# Updating number of batches to: ' || ln_new_num_of_batches );
          put_log_line();
       END IF;
    ELSE
       ln_new_num_of_batches := p_number_of_batches;
    END IF;

   ln_batch_size := CEIL(p_record_count / ln_new_num_of_batches);

    IF (GB_DEBUG) THEN
       put_log_line('# Number of Records per Batch: ' || ln_batch_size );
       put_log_line();
    END IF;

    x_new_num_of_batches := ln_new_num_of_batches;
    x_batch_size := ln_batch_size;
 END;


-- +============================================================================================+ 
-- |  Name: MASTER_PROGRAM                                                                      | 
-- |  Description: This procedure is the master program that handles the creation and approval  |
-- |               of Adjustments setup as a concurrent program that will be scheduled on a     |
-- |               regular basis.                                                               |
-- |                                                                                            | 
-- |                                                                                            | 
-- |  Returns:     x_error_buffer - std conc program output buffer                              |
-- |               x_return_code  - std conc program return value                               |
-- |                                (0=Success,1=Warning,2=Error)                               |
-- +============================================================================================+
 PROCEDURE MASTER_PROGRAM
 ( x_error_buffer           OUT     VARCHAR2
  ,x_return_code            OUT     NUMBER
  ,p_org_id                 IN      NUMBER
  ,p_currency_code          IN      VARCHAR2
  ,p_amount_rem_low         IN      NUMBER
  ,p_amount_rem_high        IN      NUMBER
  ,p_due_date_low           IN      VARCHAR2
  ,p_due_date_high          IN      VARCHAR2
  ,p_cust_trx_id_low        IN      NUMBER
  ,p_cust_trx_id_high       IN      NUMBER
  ,p_activity_id            IN      NUMBER
  )
 IS
  lc_sub_name                      VARCHAR2(250)         := 'MASTER_PROGRAM';
  ld_from_date                     DATE                  := fnd_date.canonical_to_date(p_due_date_low);
  ld_to_date                       DATE                  := fnd_date.canonical_to_date(p_due_date_high);
  x_adj_rec                        AR_ADJUSTMENTS%ROWTYPE;
  x_adj_app                        AR_ADJUSTMENTS%ROWTYPE;
  x_msg_count                      NUMBER             :=0;
  x_msg_data                       VARCHAR2(4000);
  x_return_status                  VARCHAR2(250);
  x_new_adj_num                    ar_adjustments.adjustment_number%TYPE;
  x_new_adj_id                     ar_adjustments.adjustment_id%TYPE;
  x_new_adjust_id                  ar_adjustments.adjustment_id%TYPE;
  lc_chk_approval_limits           VARCHAR2(250);
  lc_check_amount                  VARCHAR2(250);
  ln_amount_remaining              NUMBER            := 0;
  ln_org_id                        NUMBER            := 0;
  ln_receivables_trx_id            NUMBER            := 0;
  lc_account_number                VARCHAR2(250);
  lc_customer_name                 VARCHAR2(250);
  lc_trx_number                    VARCHAR2(250);
  lc_trx_type                      VARCHAR2(250);
  lc_due_date                      DATE;
  lc_adjustment_number             VARCHAR2(250);
  ln_amount_adjusted               NUMBER            :=0;
  ln_amount_due_remaining          NUMBER            :=0;
  lc_status                        VARCHAR2(250);
  lc_error_loc                     VARCHAR2(4000)    := NULL;
  ln_cust_trx_id_low               NUMBER            := NULL;
  ln_cust_trx_id_high              NUMBER            := NULL;
  ln_adj_count                     NUMBER            := NULL;
  ln_adj_app_count                 NUMBER            := NULL;
  ln_adj_idx                       NUMBER            := NULL;
  ln_adj_idx_app                   NUMBER            := NULL;

  TYPE t_adj_id IS TABLE OF ar_adjustments_all.adjustment_id%TYPE INDEX BY PLS_INTEGER;
  ln_adj_id                         t_adj_id;

   CURSOR lcu_adjustment_number 
                  (cp_org_id                 IN     NUMBER
                  ,cp_currency_code          IN     VARCHAR2
                  ,cp_amount_rem_low         IN     NUMBER
                  ,cp_amount_rem_high        IN     NUMBER
                  ,cp_due_date_low           IN     DATE
                  ,cp_due_date_high          IN     DATE
                  ,cp_cust_trx_id_low        IN     NUMBER
                  ,cp_cust_trx_id_high       IN     NUMBER)
   IS
   SELECT payment_schedule_id
         ,customer_trx_id
         ,trx_number
         ,amount_due_remaining
   FROM  xx_ar_open_trans_itm XAOTI
   WHERE XAOTI.amount_due_remaining    BETWEEN cp_amount_rem_low   AND cp_amount_rem_high
   AND   XAOTI.due_date                BETWEEN cp_due_date_low     AND cp_due_date_high
   AND   XAOTI.customer_trx_id         BETWEEN cp_cust_trx_id_low  AND cp_cust_trx_id_high
   AND   XAOTI.invoice_currency_code   = cp_currency_code
   AND   org_id                        = cp_org_id
   ORDER BY customer_trx_id;

 BEGIN
  -- ==========================================================================
  -- reset master program return code status 
  --   and set program run date
  -- ==========================================================================
    lc_error_loc := 'Setting the Debug Mode to True';

    GN_RETURN_CODE := 0;
    GD_PROGRAM_RUN_DATE := SYSDATE;


    IF (GB_DEBUG) THEN
       put_current_datetime();
    END IF;

    lc_error_loc := 'Printing the Output Header';

    put_out_line('Office Depot, Inc.         OD: AR Adjustments Creation and Approval Child   Date: '
                     || TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS') );
    put_out_line('Request Id: ' || RPAD(FND_GLOBAL.CONC_REQUEST_ID,12,' ') 
                     || '                                               Page: ' || TO_CHAR(1) );
    put_out_line();
    put_out_line();
    put_out_line(' ====================== Parameters ====================== ');
    put_out_line('    Amount Remaining Low:        ' || p_amount_rem_low );
    put_out_line('    Amount Remaining High:       ' || p_amount_rem_high);
    put_out_line('    Due Date Low:                ' || TO_CHAR(ld_from_date,'DD-MON-YYYY') );
    put_out_line('    Due Date High:               ' || TO_CHAR(ld_to_date,'DD-MON-YYYY') );
    put_out_line('    Activity Name:               ' || p_activity_id );

    put_out_line('========================================= Adjustment Creation Details ==========================================');
    put_out_line
                 ( RPAD('Customer Name',25) 
                || RPAD('Customer Number',20) 
                ||'   '
                || RPAD('Invoice Number',18)
                ||'   '
                || RPAD('Invoice Type',20)
                ||'       '
                || RPAD('Due Date',12)
                ||'   '
                || RPAD('Adjustment Number',18)
                ||'   '
                || RPAD('Adjusted Amount',15)
                ||'     '
                || RPAD('Balance Due',15)
                ||'   '
                || RPAD('Adjustment Status',20) );

    put_out_line
                ( RPAD('-',20,'-')
                ||'   '
                ||RPAD('-',20,'-')
                ||'   '
                ||RPAD('-',18,'-')
                ||'   '
                ||RPAD('-',23,'-')
                ||'    '
                ||RPAD('-',12,'-')
                ||'    '
                ||RPAD('-',19,'-')
                ||'   '
                ||RPAD('-',15,'-')
                ||'    '
                ||RPAD('-',14,'-')
                ||'   '
                ||RPAD('-',20,'-'));

    lc_error_loc := 'Selecting receivables_trx_id';
    put_log_line('Activity Name: '|| p_activity_id);
    BEGIN
         SELECT receivables_trx_id
         INTO   ln_receivables_trx_id
         FROM   ar_receivables_trx_all
         WHERE  receivables_trx_id = p_activity_id;

         put_log_line('Activity ID: '|| ln_receivables_trx_id);

    EXCEPTION
            WHEN NO_DATA_FOUND THEN
                 put_log_line('No data found in '||lc_error_loc);
            WHEN OTHERS THEN
                 put_log_line('When others while '||lc_error_loc);
    END;

    ln_adj_count                  := 1;
    ln_adj_idx                    := 1;

    FOR l_adjustment_number IN lcu_adjustment_number(p_org_id
                                                    ,p_currency_code
                                                    ,p_amount_rem_low
                                                    ,p_amount_rem_high
                                                    ,ld_from_date
                                                    ,ld_to_date
                                                    ,p_cust_trx_id_low
                                                    ,p_cust_trx_id_high
                                                    )
    LOOP
     --Initializing the variables
       ln_amount_remaining     := 0;
       ln_org_id               := 0;
       lc_account_number       := NULL;
       lc_customer_name        := NULL;
       lc_trx_number           := NULL;
       lc_trx_type             := NULL;
       lc_due_date             := NULL;
       lc_adjustment_number    := NULL;
       ln_amount_adjusted      := 0;
       ln_amount_due_remaining := 0;
       lc_status               := NULL;

       BEGIN
          lc_error_loc := 'Getting the amount due remaining';

          SELECT amount_due_remaining
          INTO  ln_amount_remaining
          FROM  xx_ar_open_trans_itm
          WHERE payment_schedule_id = l_adjustment_number.payment_schedule_id;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN
               put_log_line('No data found in '||lc_error_loc||' for payment_schedule_id = '||l_adjustment_number.payment_schedule_id);
          WHEN OTHERS THEN
               put_log_line('When others while '||lc_error_loc||' for payment_schedule_id = '||l_adjustment_number.payment_schedule_id);
       END;

       BEGIN
          lc_error_loc := 'Getting the org_id';

          SELECT org_id
          INTO  ln_org_id
          FROM  xx_ar_open_trans_itm
          WHERE payment_schedule_id =l_adjustment_number.payment_schedule_id;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN
               put_log_line('No data found in '||lc_error_loc||' for payment_schedule_id = '||l_adjustment_number.payment_schedule_id);
          WHEN OTHERS THEN
               put_log_line('When others while '||lc_error_loc||' for payment_schedule_id = '||l_adjustment_number.payment_schedule_id);
       END;

       lc_error_loc := 'Calculating Amount Remaining';

       IF (ln_amount_remaining > 0) THEN
           ln_amount_remaining := -ln_amount_remaining;
       ELSIF (ln_amount_remaining <0) THEN
           ln_amount_remaining := abs(ln_amount_remaining);
       END IF;

       x_adj_rec.type                := 'INVOICE';
       x_adj_rec.payment_schedule_id := l_adjustment_number.payment_schedule_id;
       x_adj_rec.amount              := ln_amount_remaining;
       x_adj_rec.customer_trx_id     := l_adjustment_number.customer_trx_id;
       x_adj_rec.receivables_trx_id  := ln_receivables_trx_id;
       x_adj_rec.created_from        := 'ADJ-API';
       x_adj_rec.apply_date          := SYSDATE; 
       x_adj_rec.gl_date             := x_adj_rec.apply_date;
       x_adj_rec.reason_code         := 'WRITE OFF';
       x_adj_rec.comments            := 'Testing creation of adjustments thru the adj_api';

       lc_chk_approval_limits        := 'F';
       lc_check_amount               := 'T';  -- should be true while creating
       x_adj_rec.status              := 'W';

       arp_standard.enable_debug; 

       lc_error_loc := 'Calling the Create_Adjustment API';
       put_log_line();
       put_log_line('Creation of Adjustment for Invoice Number: '||l_adjustment_number.trx_number||'  With amount_due_remaining: '||ln_amount_remaining);
       AR_ADJUST_PUB.Create_Adjustment(
               p_api_name             =>   'AR_ADJUST_PUB',
               p_api_version          =>   1.0,
               p_msg_count            =>   x_msg_count ,
               p_msg_data             =>   x_msg_data,
               p_return_status        =>   x_return_status,
               p_adj_rec              =>   x_adj_rec,
               p_chk_approval_limits  =>   lc_chk_approval_limits,
               p_new_adjust_number    =>   x_new_adj_num,
               p_new_adjust_id        =>   x_new_adj_id
                                       );
       ln_adj_id(ln_adj_idx) := x_new_adj_id;
       ln_adj_idx := ln_adj_idx + 1;

       IF (ln_adj_count = 500) THEN
           COMMIT;
          --Resetting the PL/SQL table index
           ln_adj_count := 0;
       END IF;

       ln_adj_count := ln_adj_count + 1;

       put_log_line();
       put_log_line('----Creation Status----');
       put_log_line('new adj_id ' || x_new_adj_id);
       put_log_line('return status ' || x_return_status );
       put_log_line('error_count ' || x_msg_count);
       put_log_line('error_mesg ' ||  x_msg_data );
    END LOOP;
    COMMIT;

    ln_adj_app_count := 1;
    ln_adj_idx_app := 1;

    IF (ln_adj_id.COUNT > 0) THEN
        FOR i IN 1 .. (ln_adj_count -1)
        LOOP
           x_new_adjust_id := ln_adj_id(i);
           x_adj_app.type := 'LINE'; 

           lc_error_loc := 'Calling the Approve_Adjustment API';

           AR_ADJUST_PUB.Approve_Adjustment(
                      p_api_name => 'AR_ADJUST_PUB',
                      p_api_version => 1.0,
                      p_msg_count => x_msg_count ,
                      p_msg_data => x_msg_data,
                      p_return_status => x_return_status,
                      p_adj_rec => x_adj_app,
                      p_old_adjust_id => x_new_adjust_id );

          IF (ln_adj_app_count = 500) THEN
              COMMIT;
             --Resetting the PL/SQL table index
             ln_adj_app_count := 0;
          END IF;

          ln_adj_app_count := ln_adj_app_count + 1;

          put_log_line();
          put_log_line('----Approval Status----');
          put_log_line('return status ' || x_return_status );
          put_log_line('error_count ' || x_msg_count);
          put_log_line('error_mesg ' ||  x_msg_data );
          x_msg_data := NULL;


          BEGIN
             lc_error_loc := 'Selecting the Adjustment details to display in output';

             put_log_line('Adjustment ID Created and Approved: '|| x_new_adjust_id);
             put_log_line();

             SELECT HCA.account_number
                   ,HP.party_name
                   ,APS.trx_number
                   ,RCTT.name
                   ,APS.due_date
                   ,AAA.adjustment_number
                   ,AAA.amount
                   ,APS.amount_due_remaining
                   ,DECODE(AAA.status, 'A', 'Approved', 'W', 'Waiting for Approval', 'R', 'Rejected')
             INTO   lc_account_number
                   ,lc_customer_name
                   ,lc_trx_number
                   ,lc_trx_type
                   ,lc_due_date
                   ,lc_adjustment_number
                   ,ln_amount_adjusted
                   ,ln_amount_due_remaining
                   ,lc_status
             FROM   hz_cust_accounts HCA
                   ,hz_parties HP
                   ,ar_payment_schedules_all APS
                   ,ra_cust_trx_types_all RCTT
                   ,ar_adjustments_all AAA
             WHERE HCA.party_id= HP.party_id
             AND   HCA.cust_account_id=APS.customer_id
             AND   APS.cust_trx_type_id= RCTT.cust_trx_type_id
             AND   APS.payment_schedule_id=AAA.payment_schedule_id
             AND   AAA.adjustment_id=x_new_adjust_id;

-- Printing each Adjstment created and Approved to the output

             put_out_line(RPAD(lc_customer_name,25,' ')
                          ||'   '
                          ||RPAD(lc_account_number,10,' ')
                          ||LPAD(' ',10,' ')
                          ||RPAD(lc_trx_number,15,' ')
                          ||LPAD(' ',5,' ')
                          ||RPAD(lc_trx_type,20,' ') 
                          ||LPAD(' ','8',' ')
                          ||RPAD(lc_due_date,10,' ')
                          ||LPAD(' ','8',' ')
                          ||RPAD(lc_adjustment_number,10,' ')
                          ||LPAD(' ','12',' ')
                          ||RPAD(ln_amount_adjusted,10,' ')
                          ||LPAD(' ','10',' ')
                          ||RPAD(ln_amount_due_remaining,10,' ')
                          ||LPAD(' ','10',' ')
                          ||RPAD(lc_status,10,' ')
                         );

             EXCEPTION
                WHEN NO_DATA_FOUND THEN
                     put_log_line('No data found in '||lc_error_loc||' for Adjusment_id = '||x_new_adjust_id);
                WHEN OTHERS THEN
                     put_log_line('When others while '||lc_error_loc||' for Adjusment_id = '||x_new_adjust_id);
             END;
        END LOOP;
        COMMIT;
    END IF;

 EXCEPTION
    WHEN OTHERS THEN
       x_return_code := 2;
       x_error_buffer := SQLERRM||lc_error_loc;
       XX_COM_ERROR_LOG_PUB.log_error 
      ( p_program_type            => 'CONCURRENT PROGRAM'
       ,p_program_name            => 'XX_AR_AUTO_ADJ_CHILD'
       ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
       ,p_module_name             => 'AR'
       ,p_error_location          => 'Error in Child Program'
       ,p_error_message_count     => 1
       ,p_error_message_code      => 'E'
       ,p_error_message           => SQLERRM
       ,p_error_message_severity  => 'Major'
       ,p_notify_flag             => 'N'
       ,p_object_type             => lc_sub_name );
    RAISE;
 END;

-- +============================================================================================+ 
-- |  Name: MULTI_THREAD_MASTER                                                                 | 
-- |  Description: This procedure is the master program that handles the multi thread concept   |
-- |               used for submission of multiple threads of Adjustment creation and approval  |
-- |                                                                                            | 
-- |                                                                                            | 
-- |  Returns:     x_error_buffer - std conc program output buffer                              |
-- |               x_return_code  - std conc program return value                               |
-- |                                (0=Success,1=Warning,2=Error)                               |
-- +============================================================================================+

 PROCEDURE MULTI_THREAD_MASTER
 ( x_error_buffer           OUT     VARCHAR2
  ,x_return_code            OUT     NUMBER
  ,p_org_id                 IN      NUMBER
  ,p_currency_code          IN      VARCHAR2
  ,p_amount_rem_low         IN      NUMBER
  ,p_amount_rem_high        IN      NUMBER
  ,p_due_date_low           IN      VARCHAR2
  ,p_due_date_high          IN      VARCHAR2
  ,p_activity_id            IN      NUMBER
  ,p_number_of_batches      IN      NUMBER
  ,p_submit_adj_api         IN      VARCHAR2)
 IS
  lc_sub_name                 CONSTANT VARCHAR2(50)          := 'MULTI_THREAD_MASTER';
  ld_from_date                DATE                           := fnd_date.canonical_to_date(p_due_date_low);
  ld_to_date                  DATE                           := fnd_date.canonical_to_date(p_due_date_high);
  ln_batch_size               NUMBER         DEFAULT NULL;
  ln_conc_request_id          NUMBER         DEFAULT NULL;
  ln_from_index               NUMBER         DEFAULT NULL;
  ln_to_index                 NUMBER         DEFAULT NULL;
  ln_number_of_batches        NUMBER         DEFAULT NULL;
  ln_requests_submitted       NUMBER         DEFAULT NULL;
  lc_last_trx_num                            xx_ar_open_trans_itm.trx_number%TYPE;
  lc_first_trx_num                           xx_ar_open_trans_itm.trx_number%TYPE;
  ln_cust_trx_id_low          NUMBER;
  ln_cust_trx_id_high         NUMBER;
  lc_req_data                 VARCHAR2(240);
  ln_trx_index                NUMBER;
  ln_batch_number             NUMBER         := 0;
  ln_this_request_id          NUMBER         := FND_GLOBAL.CONC_REQUEST_ID;
  lc_error_loc                VARCHAR2(4000) := NULL;
  ln_err_cnt                  NUMBER         := 0;
  ln_wrn_cnt                  NUMBER         := 0;
  ln_nrm_cnt                  NUMBER         := 0;

  TYPE data_buffer_typ IS TABLE OF xx_ar_open_trans_itm.trx_number%TYPE INDEX BY PLS_INTEGER;
  t_trx_num                           data_buffer_typ;

    CURSOR lcu_create_adjustments
  ( cp_org_id                 IN     NUMBER
   ,cp_currency_code          IN     VARCHAR2
   ,cp_amount_rem_low         IN     NUMBER
   ,cp_amount_rem_high        IN     NUMBER
   ,cp_due_date_low           IN     DATE
   ,cp_due_date_high          IN     DATE)
  IS
    SELECT trx_number
    FROM  XX_AR_OPEN_TRANS_ITM
    WHERE customer_trx_id      IS NOT NULL
    AND   amount_due_remaining BETWEEN cp_amount_rem_low AND cp_amount_rem_high
    AND   due_date             BETWEEN cp_due_date_low   AND cp_due_date_high
    AND   invoice_currency_code = cp_currency_code
    AND   org_id                = cp_org_id
    ORDER BY customer_trx_id;

 BEGIN
  -- ==========================================================================
  -- Debug can always be on for parent request
  -- ==========================================================================
   put_log_line('Checking Error location');
   lc_error_loc := 'Setting the Debug Mode to True';
   GB_DEBUG := TRUE;
   GN_RETURN_CODE := 0;

  -- ==========================================================================
  -- if initial execution (first step)
  -- ==========================================================================
    IF (NVL(lc_req_data,'FIRST') = 'FIRST')  THEN
       IF (GB_DEBUG) THEN
          put_log_line();
          put_log_line('BEGIN ' || lc_sub_name);
       END IF;

    -- ==========================================================================
    -- Validate the Number of Batches
    -- ==========================================================================
       lc_error_loc := 'Validating Number of Batches';
       put_log_line('Checking Batch Count');
       IF (NVL(p_number_of_batches,0) <= 0) THEN
          RAISE_APPLICATION_ERROR
          ( -20093, 'Number of Batches "p_number_of_batches" must be greater than zero.' );
       END IF;

  -- ==========================================================================
  -- create data variable from date parameter
  -- ==========================================================================
       lc_error_loc := 'Creating date variable from date parameter';

       put_log_line('- Set the date variables: ');
--    ld_from_date := FND_DATE.CANONICAL_TO_DATE(p_due_date_low);
--    ld_to_date   := FND_DATE.CANONICAL_TO_DATE(p_due_date_high);

  -- ==========================================================================
  -- Execute the first step of this program 
  -- ==========================================================================

       put_log_line('Checking Program Status');
       IF (p_submit_adj_api ='Y') THEN
           lc_req_data := FND_CONC_GLOBAL.REQUEST_DATA;
           IF ( lc_req_data = 'OVER' ) THEN
               RETURN;
           END IF;
       END IF;

       lc_error_loc := 'At Step 1';

       IF (NVL(lc_req_data,'FIRST') = 'FIRST')  THEN
           IF (GB_DEBUG) THEN
               put_log_line('At Step ' || NVL(lc_req_data,'FIRST') );
               put_log_line();
           END IF;

    -- ==========================================================================
    -- print to output the header and parameters
    -- ==========================================================================
           lc_error_loc := 'print to output the header and parameters';

           put_out_line('Office Depot, Inc.                OD: AR Adjustments Creation and Approval Master                 Date: '
                        || TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS') );
           put_out_line('Request Id: ' || RPAD(FND_GLOBAL.CONC_REQUEST_ID,12,' ') 
                        || '                                               Page: ' || TO_CHAR(1) );
           put_out_line();
           put_out_line();
           put_out_line(' ====================== Parameters ====================== ');
           put_out_line('    ORG ID:                      ' || p_org_id );
           put_out_line('    Currency Code       :        ' || p_currency_code);
           put_out_line('    Amount Remaining Low:        ' || p_amount_rem_low );
           put_out_line('    Amount Remaining High:       ' || p_amount_rem_high);
           put_out_line('    Due Date Low:                ' || TO_CHAR(ld_from_date,'DD-MON-YYYY') );
           put_out_line('    Due Date High:               ' || TO_CHAR(ld_to_date,'DD-MON-YYYY') );
           put_out_line('    Activity Name:               ' || p_activity_id);
           put_out_line('    Number of Batches:           ' || p_number_of_batches );
           put_out_line('    Submit Adjustments Program   ' || p_submit_adj_api );
           put_out_line();
           put_out_line();

           ln_trx_index := 1;

           FOR l_create_adjustments IN lcu_create_adjustments (p_org_id
                                                              ,p_currency_code
                                                              ,p_amount_rem_low
                                                              ,p_amount_rem_high
                                                              ,ld_from_date
                                                              ,ld_to_date
                                                              )
           LOOP

              t_trx_num(ln_trx_index) := l_create_adjustments.trx_number;
              ln_trx_index := ln_trx_index +1;

           END LOOP;

           IF (GB_DEBUG) THEN
               put_log_line('# Number of Transactions selected : ' || t_trx_num.COUNT );
               put_log_line('# Number of Batches Parameter: ' || p_number_of_batches );
               put_log_line();
           END IF;

          ln_requests_submitted := 0;
          ln_trx_index          := 0;

          lc_error_loc := 'Getting the batch size';

          IF (t_trx_num.COUNT > 0) THEN
              get_batch_size
                ( p_number_of_batches  => p_number_of_batches
                 ,p_record_count       => t_trx_num.COUNT
                 ,x_new_num_of_batches => ln_number_of_batches
                 ,x_batch_size         => ln_batch_size );

             FOR i_index IN 1..ln_number_of_batches LOOP

                 ln_trx_index       := ln_trx_index + 1;
                 ln_batch_number    := ln_batch_number + 1;
                 lc_first_trx_num   := t_trx_num(ln_trx_index);
                 ln_trx_index       := ln_trx_index + ln_batch_size -1;

                 IF( ln_trx_index > t_trx_num.count) THEN
                     ln_trx_index := t_trx_num.count;
                 END IF;

                 lc_last_trx_num   := t_trx_num(ln_trx_index);

                 put_log_line('-------------------------------------');
                 put_log_line('Batch Number:  '||ln_batch_number);
                 put_log_line('First Transaction: '||lc_first_trx_num);
                 put_log_line('Last Transaction:  '||lc_last_trx_num);
                 put_log_line('');

                 lc_error_loc := 'Checking if Adjusments Creation Program should be submitted';

                 IF (p_submit_adj_api ='Y') THEN

                     put_log_line('===========================================================');
                     put_log_line('First Transaction: '||lc_first_trx_num);
                     put_log_line('Last Transaction:  '||lc_last_trx_num);
                     put_log_line(' ');

                     lc_error_loc := 'Selecting customer_trx_id_low';
                     BEGIN
                        SELECT customer_trx_id
                        INTO   ln_cust_trx_id_low
                        FROM   ra_customer_trx_all
                        WHERE  trx_number = lc_first_trx_num;
                     EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                             put_log_line('No data found in '||lc_error_loc);
                        WHEN OTHERS THEN
                             put_log_line('When others while '||lc_error_loc);
                        END;

                     lc_error_loc := 'Selecting customer_trx_id_high';

                     BEGIN
                        SELECT customer_trx_id
                        INTO   ln_cust_trx_id_high
                        FROM   ra_customer_trx_all
                        WHERE  trx_number = lc_last_trx_num;
                     EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                             put_log_line('No data found in '||lc_error_loc);
                        WHEN OTHERS THEN
                             put_log_line('When others while '||lc_error_loc);
                     END; 

                     ln_conc_request_id := FND_REQUEST.submit_request(
                                                                       application    => 'XXFIN'
                                                                      ,program        => 'XX_AR_AUTO_ADJ_CHILD' 
                                                                      ,description    => ''
                                                                      ,start_time     => ''
                                                                      ,sub_request    => TRUE
                                                                      ,argument1      => p_org_id
                                                                      ,argument2      => p_currency_code
                                                                      ,argument3      => p_amount_rem_low
                                                                      ,argument4      => p_amount_rem_high
                                                                      ,argument5      => p_due_date_low
                                                                      ,argument6      => p_due_date_high 
                                                                      ,argument7      => ln_cust_trx_id_low
                                                                      ,argument8      => ln_cust_trx_id_high
                                                                      ,argument9      => p_activity_id
                                                                      );

                     put_log_line( 'Submitted Concurrent Request ID: ' || ln_conc_request_id || '.' );
                     put_log_line(' ');
                  END IF;
               END LOOP;

          -- ===========================================================================
          -- check if request was successful, otherwise update the log
          -- ===========================================================================
               IF (p_submit_adj_api ='Y') THEN
                   FND_CONC_GLOBAL.set_req_globals(conc_status   => 'PAUSED', request_data  => 'OVER' );
                   COMMIT;
                   IF (ln_conc_request_id > 0) THEN
                      COMMIT;
                      ln_requests_submitted := ln_requests_submitted + 1;
                      IF (GB_DEBUG) THEN
                          put_log_line();
                      END IF;
                  END IF;
                  RETURN;
               ELSE
                   put_log_line();
                   put_log_line ('Requests were not submitted') ;
                   put_log_line();
               END IF;

               put_out_line(' =============== Create Adjustents ================= ');
               put_out_line('    Number of Records: '            || t_trx_num.COUNT );
               put_out_line('    Planned Number of Batches: '    || p_number_of_batches );
               put_out_line('    Actual Number of Batches: '     || ln_number_of_batches );
               put_out_line('    Batch Size: '                   || ln_batch_size );
               put_out_line('    Number of Requests Submitted: ' || ln_requests_submitted );
               put_out_line();
               put_out_line();

   --     FND_CONC_GLOBAL.set_req_globals(conc_status   => 'PAUSED', request_data  => 'OVER' );
 --       COMMIT;

  --      RETURN;

            END IF;

       END IF;

    END IF;

  -- ==========================================================================
  -- set master program return code depending on the status of child requests
  -- ==========================================================================
    IF (p_submit_adj_api ='Y') THEN
        put_log_line('Check OD: AR Adjustments Creation and Approval Parallel - Child Status - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );
        lc_error_loc := 'Setting the status of the Master Program';

         BEGIN
            SELECT SUM(CASE WHEN status_code = 'E'
                       THEN 1 ELSE 0 END)
                  ,SUM(CASE WHEN status_code = 'G'
                       THEN 1 ELSE 0 END)
                  ,SUM(CASE WHEN status_code = 'C'
                       THEN 1 ELSE 0 END)
            INTO   ln_err_cnt
                  ,ln_wrn_cnt
                 ,ln_nrm_cnt
            FROM   fnd_concurrent_requests
            WHERE   parent_request_id = ln_this_request_id;

            IF (ln_err_cnt > 0 AND ln_wrn_cnt > 0) THEN
                put_log_line('OD: AR Adjustments Creation and Approval - Child ended in Error/Warning');
                x_error_buffer    := 'OD: AR Adjustments Creation and Approval - Child ended in Error/Warning';
                x_return_code     := 2;
            ELSIF (ln_wrn_cnt >0 AND ln_err_cnt = 0) THEN
                put_log_line('OD: AR Adjustments Creation and Approval - Child ended in Warning');
                x_error_buffer    := 'OD: AR Adjustments Creation and Approval - Child ended in Warning';
                x_return_code     := 1;
            ELSIF (ln_err_cnt >0 AND ln_wrn_cnt = 0) THEN
                put_log_line('OD: AR Adjustments Creation and Approval - Child ended in Error');
                x_error_buffer    := 'OD: AR Adjustments Creation and Approval - Child ended in Error';
                x_return_code     := 2;
            END IF;

         EXCEPTION
            WHEN OTHERS THEN
               put_log_line('Error @ Custom Child Program Status Check');
               x_error_buffer    := 'Error @ Custom Child Program Status Check';
         END;
    END IF;

  EXCEPTION
     WHEN OTHERS THEN
       x_return_code := 2;
       x_error_buffer := SQLERRM||lc_error_loc;
       XX_COM_ERROR_LOG_PUB.log_error 
      ( p_program_type            => 'CONCURRENT PROGRAM',
       p_program_name            => 'XX_AR_ADJ_MASTER',
       p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID,
       p_module_name             => 'AR',
       p_error_location          => 'Error in Multi-Thread Master Program',
       p_error_message_count     => 1,
       p_error_message_code      => 'E',
       p_error_message           => SQLERRM,
       p_error_message_severity  => 'Major',
       p_notify_flag             => 'N',
       p_object_type             => lc_sub_name );
 END;

END;
/
SHOW ERROR