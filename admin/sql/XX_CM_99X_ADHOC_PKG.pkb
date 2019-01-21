SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_CM_99X_ADHOC_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE  BODY XX_CM_99X_ADHOC_PKG  
AS

-- +========================================================================+
-- |                  Office Depot - Project Simplify                       |
-- |                       WIPRO Technologies                               |
-- +========================================================================+
-- | Name : XX_CM_99X_ADHOC_PKG                                             |
-- | RICE ID :  R1161                                                       |
-- | Description :This package is the executable of the wrapper program     |
-- |              that used for submitting the OD: CM 996 AdHoc Report (or) |
-- |              OD: CM 998 AdHoc Report (or) OD: CM 999 AdHoc Report      |
-- |              based on the input parameters for the user and the        | 
-- |  		  default format is EXCEL                                   |
-- |                                                                        |
-- |                                                                        |
-- | Change Record:                                                         |
-- |===============                                                         |
-- |Version   Date              Author              Remarks                 |
-- |======   ==========     =============        =======================    |
-- |Draft 1A  19-FEB-10     Mohammed Appas          Initial version         |
-- | 1.0      21-APR-10     Mohammed Appas          Defect#5356, 5360       |
-- |                                                                        |
-- +========================================================================+

-- +=====================================================================+  |
-- | Name :  XX_CM_99X_ADHOC_PROC                                           |
-- | Description : The procedure will submit the OD: CM 996 AdHoc Report    |
-- |               (or) OD: CM 998 AdHoc Report                             |
-- |               (or) OD: CM 999 AdHoc Report                             |
-- |                                                                        |
-- | Parameters  : P_99X, P_SUMMARY_DETAIL, P_BANKREC_ID_DATE, P_BANKREC_ID,|
-- |               P_TRXDATE_FROM, P_TRXDATE_TO, P_LOCATION, P_PROCESSOR_ID,|
-- |               P_AMOUNT                                                 |
-- | Returns     : x_err_buff,x_ret_code                                    |
-- +=====================================================================+

 PROCEDURE XX_CM_99X_ADHOC_PROC( x_err_buff             OUT VARCHAR2
                                ,x_ret_code             OUT NUMBER
                                ,P_99X                  IN  VARCHAR2
                                ,P_SUMMARY_DETAIL       IN  VARCHAR2
                                --,P_BANKREC_ID_TRX_DATE  IN  VARCHAR2          --Commented for Defect# 5356/5360
                                --,P_DUMMY                IN  VARCHAR2          --Commented for Defect# 5356/5360
                                ,P_BANKREC_ID_DATE      IN  VARCHAR2            --Added for Defect# 5356/5360
                                ,P_DUMMY_BANK_REC_ID    IN  VARCHAR2            --Added for Defect# 5356/5360
                                ,P_DUMMY_TRX_DATE       IN  VARCHAR2            --Added this parameter P_DUMMY_TRX_DATE for Defect# 5356/5360
                                ,P_BANKREC_ID           IN  VARCHAR2            --Added this parameter P_BANKREC_ID for Defect# 5356/5360
                                ,P_TRXDATE_FROM         IN  DATE
                                ,P_TRXDATE_TO           IN  DATE
                                ,P_DUMMY2               IN  VARCHAR2
                                ,P_LOCATION             IN  VARCHAR2
                                ,P_PROCESSOR_ID         IN  VARCHAR2
                                ,P_AMOUNT               IN  NUMBER
                               )
 AS
  -- Local Variable declaration
   ln_request_id        NUMBER(15);
   lb_layout            BOOLEAN;
   lb_req_status        BOOLEAN;
   lb_print_option      BOOLEAN;
   lc_status_code       VARCHAR2(10);
   lc_phase             VARCHAR2(50);
   lc_status            VARCHAR2(50);
   lc_devphase          VARCHAR2(50);
   lc_devstatus         VARCHAR2(50);
   lc_message           VARCHAR2(50);
   ld_short_name        VARCHAR2(50);
  
 BEGIN

    IF(P_99X = '996') THEN
       ld_short_name := 'XXCE996ADHOC';
    ELSIF(P_99X = '998') THEN
       ld_short_name := 'XXCE998ADHOC';
    ELSIF(P_99X = '999') THEN
       ld_short_name := 'XXCE999ADHOC';
    END IF;

    lb_print_option := FND_REQUEST.SET_PRINT_OPTIONS(
                                                      printer           => 'XPTR'
                                                     ,copies           => 1
                                                    );
  
  
    lb_layout := fnd_request.add_layout(
                                         'XXFIN'
                                        ,ld_short_name
                                        ,'en'
                                        ,'US'
                                        ,'EXCEL'
                                        );
     
    
    ln_request_id := FND_REQUEST.SUBMIT_REQUEST(
                                                 'XXFIN'
                                                ,ld_short_name
                                                ,NULL
                                                ,NULL
                                                ,FALSE
                                                ,P_SUMMARY_DETAIL
                                                 --,P_BANKREC_ID_TRX_DATE  IN  VARCHAR2          --Commented for Defect# 5356/5360
                                                 --,P_DUMMY                IN  VARCHAR2          --Commented for Defect# 5356/5360
                                                ,P_BANKREC_ID_DATE                               --Added for Defect# 5356/5360
                                                ,P_DUMMY_BANK_REC_ID                             --Added for Defect# 5356/5360
                                                ,P_DUMMY_TRX_DATE                                --Added this parameter P_DUMMY_TRX_DATE for Defect# 5356/5360
                                                ,P_BANKREC_ID                                    --Added this parameter P_BANKREC_ID for Defect# 5356/5360
                                                ,P_TRXDATE_FROM
                                                ,P_TRXDATE_TO
                                                ,P_DUMMY2
                                                ,P_LOCATION
                                                ,P_PROCESSOR_ID
                                                ,P_AMOUNT
                                               );

    COMMIT;

    lb_req_status := FND_CONCURRENT.WAIT_FOR_REQUEST(
                                                      request_id  => ln_request_id
                                                     ,interval    => '2'
                                                     ,max_wait    => ''
                                                     ,phase       => lc_phase
                                                     ,status      => lc_status
                                                     ,dev_phase   => lc_devphase
                                                     ,dev_status  => lc_devstatus
                                                     ,message     => lc_message
                                                    );

    IF ln_request_id <> 0 THEN
     
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The report has been submitted and the request id is: '||ln_request_id);
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Completed Sucessfully ');
     
     
       IF lc_devstatus ='E' THEN
     
          x_err_buff := 'PROGRAM COMPLETED IN ERROR';
          x_ret_code := 2;
     
       ELSIF lc_devstatus ='G' THEN
     
          x_err_buff := 'PROGRAM COMPLETED IN WARNING';
          x_ret_code := 1;
     
       ELSE
     
          x_err_buff := 'PROGRAM COMPLETED NORMAL';
          x_ret_code := 0;
     
       END IF;
     
     ELSE 
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The report did not get submitted');

     END IF;

 END XX_CM_99X_ADHOC_PROC; 

END XX_CM_99X_ADHOC_PKG; 
/

SHO ERR;