SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

PROMPT
PROMPT 'Creating XX_OIC_INCENTIVE_PKG package body'
PROMPT


 CREATE OR REPLACE PACKAGE BODY XX_OIC_INCENTIVE_PKG
 -- +===================================================================================== +
 -- |                  Office Depot - Project Simplify                                     |
 -- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                          |
 -- +===================================================================================== +
 -- |                                                                                      |
 -- | Name             : XX_OIC_INCENTIVE_PKG                                              |
 -- | Description      : This custom package extracts the OIC Payment details              |
 -- |                    from Oracle Incentive Compensation and populates the custom table |
 -- |                    XX_OIC_PAYMENT_DETAILS_STG.This will also purge the payment table |
 -- |                    and the audit table                                               |
 -- |                                                                                      |
 -- | This package contains the following sub programs:                                    |
 -- | =================================================                                    |
 -- |Type         Name                  Description                                        |
 -- |=========    ===========           ================================================   |
 -- |PROCEDURE    MAIN_PROC             This procedure will be used to extract and insert  |
 -- |                                   the OIC payment details and to raise the custom    |
 -- |                                   business event                                     |
 -- |PROCEDURE    PURGE_PROC            This procedure will be used to purge the custom    |
 -- |                                   payment details and audit history table            |
 -- |                                           .                                          |
 -- |Change Record:                                                                        |
 -- |===============                                                                       |
 -- |Version   Date         Author           Remarks                                       |
 -- |=======   ==========   =============    ============================================= |
 -- |Draft 1a  27-Aug-2007  Gowri Nagarajan  Initial draft version                         |
 -- |Draft 1b  04-Oct-2007  Susheel Raina    Reviewed and Updated                          |
 -- |Draft 1c  18-Oct-2007  Gowri Nagarajan  Added the operating unit derivation           |
 -- |Draft 1d  12-Nov-2007  Gowri Nagarajan  Modified LOG_ERROR procedure                  |
 -- +===================================================================================== +

 AS

    -- ----------------------------
    -- Declaring Global Constants
    -- ----------------------------

    G_USER_ID        CONSTANT PLS_INTEGER :=  FND_GLOBAL.USER_ID ;
    G_APPN_NAME      CONSTANT VARCHAR2(30):= 'XXCRM';   
    G_PROGRAM_TYPE   CONSTANT VARCHAR2(40):= 'I0607_IncentiveAndBonusToPayroll';
    G_MODULE_NAME    CONSTANT VARCHAR2(30):= 'CN';    
    G_ERROR_STATUS   CONSTANT VARCHAR2(30):= 'ACTIVE';
    G_NOTIFY_FLAG    CONSTANT VARCHAR2(1) :=  'Y';
    G_ORG_ID         CONSTANT PLS_INTEGER :=  FND_PROFILE.VALUE('ORG_ID');    

    -- ---------------------------
    -- Global Variable Declaration
    -- ---------------------------
    gn_insert_cnt     NUMBER := 0;
    gn_conc_req_id    NUMBER := FND_GLOBAL.CONC_REQUEST_ID;

    -- +===================================================================== +
    -- | Name       : LOG_ERROR                                               |
    -- |                                                                      |
    -- | Description: This procedure will be used to insert the error details |
    -- |              into the common error log table                         |
    -- +======================================================================+

    PROCEDURE LOG_ERROR
                       (
                        p_program_name            IN  VARCHAR2
                      , p_error_location          IN  VARCHAR2
                      , p_error_message_code      IN  VARCHAR2
                      , p_error_message           IN  VARCHAR2
                      , p_error_message_severity  IN  VARCHAR2                     
                      , p_attribute1              IN  VARCHAR2
                      , p_attribute2              IN  VARCHAR2
                      , p_attribute3              IN  VARCHAR2
                      )
    AS
       -- --------------------------
       -- Local Variable Declaration
       -- --------------------------

    BEGIN

       XX_COM_ERROR_LOG_PUB.LOG_ERROR_CRM (
                                          p_application_name        => G_APPN_NAME
                                         ,p_program_type            => G_PROGRAM_TYPE
                                         ,p_program_name            => p_program_name
                                         ,p_program_id              => gn_conc_req_id
                                         ,p_module_name             => G_MODULE_NAME
                                         ,p_error_location          => p_error_location
                                         ,p_error_message_code      => p_error_message_code
                                         ,p_error_message           => p_error_message
                                         ,p_error_message_severity  => p_error_message_severity
                                         ,p_error_status            => G_ERROR_STATUS
                                         ,p_notify_flag             => G_NOTIFY_FLAG
                                         ,p_attribute1              => p_attribute1
                                         ,p_attribute2              => p_attribute2
                                         ,p_attribute3              => p_attribute3
                                       );
    END LOG_ERROR;

    -- +====================================================================+
    -- | Name        :  DISPLAY_LOG                                         |
    -- | Description :  This procedure is invoked to print in the log file  |
    -- |                                                                    |
    -- | Parameters  :  Log Message                                         |
    -- +====================================================================+

    PROCEDURE DISPLAY_LOG(
                          p_message IN VARCHAR2
                         )

    IS
       -- --------------------------
       -- Local Variable Declaration
       -- --------------------------

       lc_error_message VARCHAR2(4000);

    BEGIN

       FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);

    EXCEPTION
       WHEN OTHERS THEN

          FND_FILE.PUT_LINE(FND_FILE.LOG,'Inside When others Exception of DISPLAY_LOG');

          FND_MESSAGE.SET_NAME('XXCRM','XX_OIC_0005_LOGGING_F');
          FND_MESSAGE.SET_TOKEN('SQLERR',SQLERRM);
          lc_error_message := FND_MESSAGE.GET;

          FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);

          LOG_ERROR (
                     p_program_name            => 'XX_OIC_INCENTIVE_PKG.DISPLAY_LOG'
                    ,p_error_location          => 'XX_OIC_INCENTIVE_PKG.DISPLAY_LOG'
                    ,p_error_message_code      => 'XX_OIC_0005_LOGGING_F'
                    ,p_error_message           =>  lc_error_message
                    ,p_error_message_severity  => 'MINOR'
                    ,p_attribute1              =>  NULL
                    ,p_attribute2              =>  NULL
                    ,p_attribute3              =>  NULL
                    );

    END DISPLAY_LOG;

    -- +====================================================================+
    -- | Name        :  DISPLAY_OUT                                         |
    -- | Description :  This procedure is invoked to print in the output    |
    -- |                file                                                |
    -- |                                                                    |
    -- | Parameters  :  Log Message                                         |
    -- +====================================================================+

    PROCEDURE DISPLAY_OUT(
                          p_message IN VARCHAR2
                         )

    IS
       -- --------------------------
       -- Local Variable Declaration
       -- --------------------------

       lc_error_message VARCHAR2(4000);

    BEGIN

       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);

    EXCEPTION
       WHEN OTHERS THEN

          FND_FILE.PUT_LINE(FND_FILE.LOG,'Inside When others Exception of DISPLAY_OUT');

          FND_MESSAGE.SET_NAME('XXCRM','XX_OIC_0005_LOGGING_F');
          FND_MESSAGE.SET_TOKEN('SQLERR',SQLERRM);
          lc_error_message := FND_MESSAGE.GET;

          FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);

          LOG_ERROR (
                    p_program_name            => 'XX_OIC_INCENTIVE_PKG.DISPLAY_OUT'
                   ,p_error_location          => 'XX_OIC_INCENTIVE_PKG.DISPLAY_OUT'
                   ,p_error_message_code      => 'XX_OIC_0005_LOGGING_F'
                   ,p_error_message           =>  lc_error_message
                   ,p_error_message_severity  => 'MINOR'
                   ,p_attribute1              =>  NULL
                   ,p_attribute2              =>  NULL
                   ,p_attribute3              =>  NULL
                   );

    END DISPLAY_OUT;

    -- +===================================================================== +
    -- | Name       : RAISE_BUSSINESS_EVENT                                   |
    -- |                                                                      |
    -- | Description: This procedure will be used to raise the custom business|
    -- |              event                                                   |
    -- |                                                                      |
    -- | Parameters : p_payrun           IN  Payrun Name                      |
    -- |              p_operating_unit   IN  Operating Unit Name              |
    -- |              x_retcode          OUT Holds '0','1','2'                |
    -- |              x_errbuf           OUT Holds the error message          |
    -- +======================================================================+

    PROCEDURE RAISE_BUSSINESS_EVENT(
                                    p_payrun         IN  VARCHAR2
                                   ,p_operating_unit IN  VARCHAR2
                                   ,x_err_msg        OUT VARCHAR2
                                   ,x_retcode        OUT NUMBER
                                   )
    IS
       -- --------------------------
       -- Local Variable Declaration
       -- --------------------------

       lc_event_name     VARCHAR2(1000):= 'od.oracle.apps.cn.BonusToPayroll.create';
       lc_event_key      VARCHAR2(1000):= p_payrun||':'||p_operating_unit;

    BEGIN

       DISPLAY_LOG('Raising the custom business event'||' '||lc_event_name);

       -- ---------------------------
       -- Raise custom business event
       -- ---------------------------

       WF_EVENT.RAISE(p_event_name  => lc_event_name
                     ,p_event_key   => lc_event_key 
                     );

       DISPLAY_LOG('Custom Business Event raised with Event Key: '||lc_event_key);

       COMMIT;

       x_retcode := 0;

    EXCEPTION
       WHEN OTHERS THEN

          DISPLAY_LOG('Inside When Others Exception of RAISE_BUSSINESS_EVENT procedure');

          FND_MESSAGE.SET_NAME('XXCRM','XX_OIC_0006_RAISE_F');
          FND_MESSAGE.SET_TOKEN('SQLERR',SQLERRM);

          x_err_msg  := FND_MESSAGE.GET;
          x_retcode  := 2;

          LOG_ERROR (
                    p_program_name            => 'XX_OIC_INCENTIVE_PKG.RAISE_BUSSINESS_EVENT'
                   ,p_error_location          => 'XX_OIC_INCENTIVE_PKG.RAISE_BUSSINESS_EVENT'
                   ,p_error_message_code      => 'XX_OIC_0006_RAISE_F'
                   ,p_error_message           =>  x_err_msg
                   ,p_error_message_severity  => 'MAJOR'
                   ,p_attribute1              =>  lc_event_name
                   ,p_attribute2              =>  NULL
                   ,p_attribute3              =>  NULL
                   );

    END RAISE_BUSSINESS_EVENT;

    -- +===================================================================== +
    -- | Name       : CHECK_RECORD_EXISTANCE                                  |
    -- |                                                                      |
    -- | Description: This procedure will be used to extract the OIC payment  |
    -- |              details                                                 |
    -- |                                                                      |
    -- | Parameters : p_payrun           IN  Payrun Name                      |
    -- |              p_period           IN  Period Name                      |
    -- |              x_errbuf           OUT Holds the error message          |
    -- |              x_cnt              OUT Holds the record count           |
    -- +======================================================================+

    PROCEDURE CHECK_RECORD_EXISTANCE
                                   (
                                     x_errbuf             OUT VARCHAR2
                                   , x_cnt                OUT NUMBER
                                   , p_period             IN  VARCHAR2
                                   , p_payrun             IN  VARCHAR2
                                   )
    AS
       -- --------------------------
       -- Local Variable Declaration
       -- --------------------------

    BEGIN

       DISPLAY_LOG('Inside CHECK_RECORD_EXISTANCE procedure');

       x_cnt    := 0;

       SELECT   COUNT('Y')
       INTO     x_cnt
       FROM     xx_oic_payment_details_stg XOPD
       WHERE    XOPD.org_id        = G_ORG_ID
       AND      XOPD.payrun_name   = p_payrun
       AND      XOPD.period        = p_period;

    EXCEPTION

       WHEN OTHERS THEN

          x_cnt    := NULL;

          DISPLAY_LOG('Inside When Others Exception of CHECK_RECORD_EXISTANCE procedure');

          FND_MESSAGE.SET_NAME('XXCRM','XX_OIC_0001_CHECKRECORD_F');
          FND_MESSAGE.SET_TOKEN('SQLERR',SQLERRM);
          x_errbuf := FND_MESSAGE.GET;

          LOG_ERROR (
                     p_program_name            => 'XX_OIC_INCENTIVE_PKG.CHECK_RECORD_EXISTANCE'
                    ,p_error_location          => 'XX_OIC_INCENTIVE_PKG.CHECK_RECORD_EXISTANCE'
                    ,p_error_message_code      => 'XX_OIC_0001_CHECKRECORD_F'
                    ,p_error_message           =>  x_errbuf
                    ,p_error_message_severity  => 'MAJOR'
                    ,p_attribute1              =>  p_payrun
                    ,p_attribute2              =>  p_period
                    ,p_attribute3              =>  NULL
                    );

    END CHECK_RECORD_EXISTANCE;

    -- +===================================================================== +
    -- | Name       : MAIN_PROC                                               |
    -- |                                                                      |
    -- | Description: This procedure will be used to extract the OIC payment  |
    -- |              details                                                 |
    -- |                                                                      |
    -- | Parameters : p_period   IN  Period Name                              |
    -- |              p_payrun   IN  Payrun Name                              |
    -- |              x_retcode  OUT Holds '0','1','2'                        |
    -- |              x_errbuf   OUT Holds the error message                  |
    -- +======================================================================+

    PROCEDURE MAIN_PROC
                    (
                      x_errbuf           OUT VARCHAR2
                    , x_retcode          OUT NUMBER
                    , p_period           IN  VARCHAR2
                    , p_payrun           IN  VARCHAR2
                    )
    AS
       
       -- ---------------------
       -- Exception Declaration
       -- ---------------------
       
       EX_INCORRECT_PARAMETERS EXCEPTION;
       EX_OU_NULL              EXCEPTION;
       
       -- --------------------------
       -- Local Variable Declaration
       -- --------------------------
       lc_err_msg           VARCHAR2(4000)   ;
       lc_err_bizevnt       VARCHAR2(4000)   ;
       lc_op_unit           VARCHAR2(240)    ;
       lc_raise_event       VARCHAR2(1)      := 'N';
       ln_retcode           NUMBER           ;
       ln_cnt               NUMBER           ;       
       
       -- ----------------------------------------------------------
       -- Get data to display in the Out file for the concurrent run
       -- ----------------------------------------------------------

       CURSOR lcu_get_data
       IS
       SELECT
               RECORD_ID
             , REQUEST_ID
             , PAYRUN_NAME
             , SALES_REP_EMPLOYEE_ID
             , SALES_REP_NAME
             , PAYMENT_AMOUNT
             , PERIOD
             , PAYMENT_DATE
             , OPERATING_UNIT
             , ORG_ID
             , PLAN_ELEMENT_NAME
             , PLAN_ELEMENT_SUBTOTAL
             , CREATED_BY
             , CREATION_DATE
             , LAST_UPDATE_DATE
             , LAST_UPDATED_BY
             , LAST_UPDATED_LOGIN
       FROM    XX_OIC_PAYMENT_DETAILS_STG
       WHERE   request_id = gn_conc_req_id;

    BEGIN

       DISPLAY_LOG('Inside MAIN_PROC procedure');

       x_retcode := 0;

       DISPLAY_OUT(RPAD(' ',375,'-'));
       DISPLAY_OUT(RPAD(' Office Depot-North America',308)||LPAD('Date:'||trunc(sysdate),65));
       DISPLAY_OUT(RPAD(' OD: OIC Incentive and Bonus to Payroll Outbound',308));
       DISPLAY_OUT(RPAD(' ',375,''));       
       DISPLAY_OUT(RPAD(' ',375,'-'));

       IF  p_period IS NULL OR p_payrun IS NULL THEN
           RAISE EX_INCORRECT_PARAMETERS ;
       END IF;
       
       DISPLAY_OUT(RPAD(' RECORD_ID',20)
                 ||RPAD('REQUEST_ID',20)
                 ||RPAD('PAYRUN_NAME',20)
                 ||RPAD('SALES_REP_EMPLOYEE_ID',25)
                 ||RPAD('SALES_REP_NAME',20)
                 ||LPAD('PAYMENT_AMOUNT',20)
                 ||RPAD(NVL(' ',''),12)
                 ||RPAD('PERIOD',20)
                 ||RPAD('PAYMENT_DATE',20)
                 ||RPAD('OPERATING_UNIT',20)
                 ||RPAD('ORG_ID',20)
                 ||RPAD('PLAN_ELEMENT_NAME',27)
                 ||LPAD(NVL('PLAN_ELEMENT_SUBTOTAL',''),22)
                 ||RPAD(NVL(' ',''),12)                 
                 ||RPAD('CREATED_BY',20)
                 ||RPAD('CREATION_DATE',20)
                 ||RPAD('LAST_UPDATE_DATE',20)
                 ||RPAD('LAST_UPDATED_BY',20)
                 ||RPAD('LAST_UPDATED_LOGIN',20));
       DISPLAY_OUT(RPAD(' ',375,'-'));

       -- -----------------------------------------------------------------
       -- Check whether the record exists in the xx_oic_payment_details_stg
       -- -----------------------------------------------------------------

       DISPLAY_LOG('Checking whether the incoming records exists in the Payments table');

       CHECK_RECORD_EXISTANCE(
                               lc_err_msg
                             , ln_cnt
                             , p_period
                             , p_payrun
                             );

       IF ln_cnt = 0 THEN

          BEGIN

             DISPLAY_LOG('Records do not exist in the Payments Stage table');
             DISPLAY_LOG(' Inserting records into the Payments Stage table...');

             -- ----------------------------------------------------------
             -- Insert payment details into the XX_OIC_PAYMENT_DETAILS_STG
             -- ----------------------------------------------------------

             INSERT INTO     xx_oic_payment_details_stg(
                             record_id
                          ,  request_id
                          ,  payrun_name
                          ,  sales_rep_employee_id
                          ,  sales_rep_name
                          ,  payment_amount
                          ,  period
                          ,  payment_date
                          ,  operating_unit
                          ,  org_id
                          ,  plan_element_name
                          ,  plan_element_subtotal
                          ,  created_by
                          ,  creation_date
                          ,  last_update_date
                          ,  last_updated_by
                          ,  last_updated_login
                           )
                            SELECT
                                   XX_OIC_PAYMENT_DETAILS_STG_S.NEXTVAL
                                 , gn_conc_req_id
                                 , CPA.name
                                 , CS.employee_number
                                 , CS.name
                                 , TOTAL.pmt_amount_calc
                                 , CP.period_name
                                 , CPA.pay_date
                                 , HOU.name
                                 , HOU.organization_id
                                 , CQA.name
                                 , CPWA.pmt_amount_calc
                                 , G_USER_ID
                                 , SYSDATE
                                 , SYSDATE
                                 , G_USER_ID
                                 , G_USER_ID
                          FROM     cn_salesreps                    CS
                                 , cn_payruns_all                  CPA
                                 , cn_payment_worksheets_all       CPWA
                                 , cn_quotas_all                   CQA
                                 , cn_payment_transactions_all     CPTA
                                 , hr_operating_units              HOU
                                 , cn_period_statuses_all          CP
                                 , cn_payment_worksheets_all       TOTAL
                           WHERE   CPA.NAME                = p_payrun
                           AND     CP.period_name          = p_period
                           AND     CS.salesrep_id          = CPWA.salesrep_id
                           AND     CPWA.salesrep_id        = CPTA.payee_salesrep_id
                           AND     CPWA.payrun_id          = CPTA.payrun_id
                           AND     CQA.quota_id            = CPTA.quota_id
                           AND     CQA.quota_id            = CPWA.quota_id
                           AND     CPWA.payrun_id          = CPA.payrun_id
                           AND     CPA.status              = 'PAID'
                           AND     CPA.org_id              = G_ORG_ID
                           AND     CPA.org_id              = HOU.organization_id
                           AND     CP.org_id               = CPA.org_id
                           AND     CPA.org_id              = CPWA.org_id
                           AND     CPWA.org_id             = CPTA.org_id
                           AND     CPTA.org_id             = CQA.org_id
                           AND     CQA.org_id              = TOTAL.org_id
                           AND     CP.period_id            = CPA.pay_period_id
                           AND     CP.period_status        = 'O'
                           AND     TOTAL.quota_id IS NULL
                           AND     TOTAL.salesrep_id       = CPTA.payee_salesrep_id
                           AND     TOTAL.payrun_id         = CPTA.payrun_id
                           AND     TOTAL.payrun_id         = CPA.payrun_id;


             gn_insert_cnt := SQL%ROWCOUNT;

             COMMIT;

             IF gn_insert_cnt = 0 THEN

                -- ----------------------------------------
                -- No data fetched ,do not raise the event
                -- ---------------------------------------

                DISPLAY_LOG('No records found for the given pay period:'||p_period||' '||'and payrun:'||p_payrun);
             ELSE

                -- --------------------------------------------------------------------------------------------------
                -- Data fetched, data did not exist from a previous run, first time data insert, will raise biz event
                -- --------------------------------------------------------------------------------------------------
                DISPLAY_LOG(' Inserted records into the Payments table');
                lc_raise_event := 'Y';

                FOR lcu_get_data_rec IN lcu_get_data
                LOOP
                   -- ------------------------------------------
                   -- Display the extracted data in the out file
                   -- ------------------------------------------
                   DISPLAY_OUT(' '
                             ||RPAD(NVL(lcu_get_data_rec.record_id,''),20)
                             ||RPAD(NVL(lcu_get_data_rec.request_id,''),20)
                             ||RPAD(NVL(lcu_get_data_rec.payrun_name,''),20)
                             ||RPAD(NVL(lcu_get_data_rec.sales_rep_employee_id,''),24)
                             ||RPAD(NVL(lcu_get_data_rec.sales_rep_name,''),20)
                             ||LPAD(NVL(lcu_get_data_rec.payment_amount,''),20)
                             ||RPAD(NVL(' ',''),12)
                             ||RPAD(NVL(lcu_get_data_rec.period,''),20)
                             ||RPAD(NVL(lcu_get_data_rec.payment_date,''),20)
                             ||RPAD(NVL(lcu_get_data_rec.operating_unit,''),20)
                             ||RPAD(NVL(lcu_get_data_rec.org_id,''),20)
                             ||RPAD(NVL(lcu_get_data_rec.plan_element_name,''),27)
                             ||LPAD(NVL(lcu_get_data_rec.plan_element_subtotal,''),22)
                             ||RPAD(NVL(' ',''),12)
                             ||RPAD(NVL(lcu_get_data_rec.created_by,''),20)
                             ||RPAD(NVL(lcu_get_data_rec.creation_date,''),20)
                             ||RPAD(NVL(lcu_get_data_rec.last_update_date,''),20)
                             ||RPAD(NVL(lcu_get_data_rec.last_updated_by,''),20)
                             ||RPAD(NVL(lcu_get_data_rec.last_updated_by,''),20)
                              );
                END LOOP;

             END IF;

          EXCEPTION
             WHEN OTHERS THEN

                ROLLBACK;
                -- ------------------------------------------------------------------
                -- Data fetched,data not exists ,insertion failure,do not raise event
                -- ------------------------------------------------------------------
                lc_raise_event := 'N';

                FND_MESSAGE.SET_NAME('XXCRM','XX_OIC_0002_INSERTION_F');
                FND_MESSAGE.SET_TOKEN('SQLERR',SQLERRM);
                x_errbuf := FND_MESSAGE.GET;

                DISPLAY_LOG(x_errbuf);

                LOG_ERROR (
                           p_program_name            => 'XX_OIC_INCENTIVE_PKG.MAIN_PROC'
                          ,p_error_location          => 'XX_OIC_INCENTIVE_PKG.MAIN_PROC'
                          ,p_error_message_code      => 'XX_OIC_0002_INSERTION_F'
                          ,p_error_message           =>  x_errbuf
                          ,p_error_message_severity  => 'MAJOR'
                          ,p_attribute1              =>  p_period
                          ,p_attribute2              =>  p_payrun
                          ,p_attribute3              =>  NULL
                          );

          END;

       -- --------------------------------------------------
       -- Data fetched,data exists ,no insertion,raise event
       -- --------------------------------------------------

       ELSIF ln_cnt > 0 THEN

          lc_raise_event := 'Y';
          -- ----------------------------------
          -- Record exists in the Payment table
          -- ----------------------------------

          DISPLAY_LOG('The records already exists for the given pay period:'||p_period||' '||'and payrun:'||p_payrun);

       ELSIF ln_cnt IS NULL THEN

          DISPLAY_LOG(lc_err_msg);

       END IF;

       IF lc_raise_event = 'Y' THEN
          
          BEGIN
             -- ----------------------------------------
             -- Derive the operating unit for the org_id --18/Oct/07
             -- ----------------------------------------
           
             SELECT name
             INTO   lc_op_unit
             FROM   hr_operating_units
             WHERE  organization_id = G_ORG_ID;          
             
          EXCEPTION                                                                                               
             
             WHEN OTHERS THEN
             
                lc_op_unit := NULL;              
                
          END;                        
          
          IF lc_op_unit IS NULL THEN
             
             DISPLAY_LOG('Business Event is not launched because the OU name is null');
             RAISE EX_OU_NULL;             
             
          ELSIF lc_op_unit IS NOT NULL THEN
          
             -- --------------------------
             -- Call RAISE_BUSSINESS_EVENT
             -- --------------------------

             RAISE_BUSSINESS_EVENT(
                                   p_payrun
                                  ,lc_op_unit
                                  ,lc_err_bizevnt
                                  ,ln_retcode
                                  );

             IF ln_retcode    = 0 THEN
                DISPLAY_LOG('Business Event Launched Successfully ');
             ELSIF ln_retcode = 2  THEN
                DISPLAY_LOG(lc_err_bizevnt);
             END IF;
          END IF;             

       ELSE
          DISPLAY_LOG('Launch of Business Event NOT required. No Condition was satisfied for a raise of Business Event.');
       END IF;

       -- ---------------------------------------------------------------------
       -- Display the summary of extracted and/or inserted data in the log file
       -- ---------------------------------------------------------------------
       DISPLAY_OUT(RPAD(' ',375,''));
       DISPLAY_OUT(LPAD(RPAD('*** End of Report - OD: OIC Incentive and Bonus to Payroll Outbound ***',138),208));
       DISPLAY_OUT(RPAD(' ',375,'-'));
       DISPLAY_OUT(' Total number of records already existing in the Custom Payments Stage Table  :'||''||ln_cnt);
       DISPLAY_OUT(' Total number of records inserted into the Custom Payments Stage Table        :'||''||gn_insert_cnt);
       DISPLAY_OUT(RPAD(' ',375,'-'));

    EXCEPTION

       WHEN EX_INCORRECT_PARAMETERS THEN
          
          DISPLAY_LOG('Inside EX_INCORRECT_PARAMETERS Exception of MAIN_PROC');

          x_retcode := 2;

          fnd_message.set_name('XXCRM','XX_OIC_0007_INCORRECT_PARAMS');
          x_errbuf := fnd_message.get;

          LOG_ERROR (
                     p_program_name            => 'XX_OIC_INCENTIVE_PKG.MAIN_PROC'
                    ,p_error_location          => 'XX_OIC_INCENTIVE_PKG.MAIN_PROC'
                    ,p_error_message_code      => 'XX_OIC_0007_INCORRECT_PARAMS'
                    ,p_error_message           =>  x_errbuf
                    ,p_error_message_severity  => 'MAJOR'
                    ,p_attribute1              =>  p_period
                    ,p_attribute2              =>  p_payrun
                    ,p_attribute3              =>  NULL
                    );
                    
       WHEN EX_OU_NULL THEN
          
          DISPLAY_LOG('Inside EX_OU_NULL Exception of MAIN_PROC');

          x_retcode := 2;

          fnd_message.set_name('XXCRM','XX_OIC_0046_OU_DERIVATION_F');
          fnd_message.set_token('SQLERR',SQLERRM);
          x_errbuf := fnd_message.get;

          LOG_ERROR (
                     p_program_name            => 'XX_OIC_INCENTIVE_PKG.MAIN_PROC'
                    ,p_error_location          => 'XX_OIC_INCENTIVE_PKG.MAIN_PROC'
                    ,p_error_message_code      => 'XX_OIC_0046_OU_DERIVATION_F'
                    ,p_error_message           =>  x_errbuf
                    ,p_error_message_severity  => 'MAJOR'
                    ,p_attribute1              =>  NULL
                    ,p_attribute2              =>  NULL
                    ,p_attribute3              =>  NULL
                    );                    
                    
       WHEN OTHERS THEN

          DISPLAY_LOG('Inside When Others Exception of MAIN_PROC');

          x_retcode := 2;

          fnd_message.set_name('XXCRM','XX_OIC_0003_MAINPROC_ERR');
          fnd_message.set_token('SQLERR',SQLERRM);
          x_errbuf := fnd_message.get;

          LOG_ERROR (
                     p_program_name            => 'XX_OIC_INCENTIVE_PKG.MAIN_PROC'
                    ,p_error_location          => 'XX_OIC_INCENTIVE_PKG.MAIN_PROC'
                    ,p_error_message_code      => 'XX_OIC_0003_MAINPROC_ERR'
                    ,p_error_message           =>  x_errbuf
                    ,p_error_message_severity  => 'MAJOR'
                    ,p_attribute1              =>  p_period
                    ,p_attribute2              =>  p_payrun
                    ,p_attribute3              =>  NULL
                    );
    END MAIN_PROC;

    -- +===================================================================== +
    -- | Name       : PURGE_PROC                                              |
    -- |                                                                      |
    -- | Description: This purge procedure will be used to purge the custom   |
    -- |              payment details and audit history table                 |
    -- |                                                                      |
    -- | Parameters : x_retcode  OUT Holds '0','1','2'                        |
    -- |              x_errbuf   OUT Holds the error message                  |
    -- +======================================================================+

    PROCEDURE PURGE_PROC
                      (
                        x_errbuf           OUT VARCHAR2
                      , x_retcode          OUT NUMBER
                      )
    AS

    BEGIN

       DISPLAY_OUT(RPAD(' ',110,'-'));
       DISPLAY_OUT(RPAD(' Office Depot-North America',90)||LPAD('Date:'||trunc(sysdate),20));
       DISPLAY_OUT(RPAD(' OD: OIC Purge Incentive Details',308));
       DISPLAY_OUT(RPAD(' ',110,'-'));
       DISPLAY_OUT(RPAD(' ',110,''));
       DISPLAY_OUT(RPAD(' ',110,''));

       -- ------------------------------------------
       -- Delete the old data from the Payment table
       -- ------------------------------------------
       DISPLAY_LOG('Deleting data from the Payments table....');
       DISPLAY_LOG('Delete Criteria: Sucessfully Transferred Records (transfer_status=Completed), and Older than 2 Years.');

       DELETE
       FROM   xx_oic_payment_details_stg XOPDS
       WHERE  XOPDS.org_id  = G_ORG_ID
       AND    XOPDS.payrun_name IN
                                  (
                                   SELECT XOPSH.payrun
                                   FROM   xx_oic_pay_status_history  XOPSH
                                   WHERE  XOPSH.org_id = G_ORG_ID
                                   AND    XOPSH.transfer_status    = 'Completed'
                                   AND    XOPSH.last_update_date  <= ADD_MONTHS (SYSDATE,-24)
                                  );

       IF SQL%ROWCOUNT = 0 THEN
          DISPLAY_LOG('No record found for deletion for the particular period in the Payments table');
       ELSIF SQL%ROWCOUNT > 0 THEN
          DISPLAY_LOG('Deleted data from the Payments table');
       END IF;

       DISPLAY_OUT(' Total number of records deleted from the Payments table :'||' '||SQL%ROWCOUNT);       

       -- ----------------------------------------
       -- Delete the old data from the Audit table
       -- ----------------------------------------
       DISPLAY_LOG('Deleting records from the Audit table....');
       DISPLAY_LOG('Delete Criteria: Sucessfully Transferred Records (transfer_status=Completed), and Older than 2 Years.');

       DELETE
       FROM   xx_oic_pay_status_history XOPSH
       WHERE  XOPSH.org_id             = G_ORG_ID
       AND    XOPSH.transfer_status    = 'Completed'
       AND    XOPSH.last_update_date  <= ADD_MONTHS (SYSDATE,-24);

       IF SQL%ROWCOUNT = 0 THEN
          DISPLAY_LOG('No record found for deletion in the Audit table');
       ELSIF SQL%ROWCOUNT > 0 THEN
          DISPLAY_LOG('Deleted records from the Audit table');
       END IF;

       DISPLAY_OUT(' Total number of records deleted from the Audit table    :'||' '||SQL%ROWCOUNT);
       DISPLAY_OUT(RPAD(' ',110,' '));
       DISPLAY_OUT(RPAD(' ',110,'-'));
       

       COMMIT;

    EXCEPTION

      WHEN OTHERS THEN

          DISPLAY_LOG('Inside When Others Exception of PURGE_PROC');

          x_retcode := 2;

          FND_MESSAGE.SET_NAME('XXCRM','XX_OIC_0004_DELETION_F');
          FND_MESSAGE.SET_TOKEN('SQLERR',SQLERRM);
          x_errbuf := FND_MESSAGE.GET;

          LOG_ERROR (
                     p_program_name            => 'XX_OIC_INCENTIVE_PKG.PURGE_PROC'
                    ,p_error_location          => 'XX_OIC_INCENTIVE_PKG.PURGE_PROC'
                    ,p_error_message_code      => 'XX_OIC_0004_DELETION_F'
                    ,p_error_message           =>  x_errbuf
                    ,p_error_message_severity  => 'MAJOR'
                    ,p_attribute1              =>  NULL
                    ,p_attribute2              =>  NULL
                    ,p_attribute3              =>  NULL
                   );

    END PURGE_PROC;

END XX_OIC_INCENTIVE_PKG;

/

SHOW ERRORS

EXIT

REM============================================================================================
REM                                   End Of Script
REM============================================================================================
