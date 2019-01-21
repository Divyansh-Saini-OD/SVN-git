CREATE OR REPLACE PACKAGE BODY APPS.XX_AR_WC_DISPUTES_TAX_PKG
AS
-- +=====================================================================+
-- |                  Office Depot - Project FIT                         |
-- |                       Cap Gemini                                    |
-- +=====================================================================+
-- | Name : XX_AR_WC_DISPUTES_TAX_PKG                                    |
-- | RICE ID :  R0536                                                    |
-- | Description :This package is the executable of the wrapper program  |
-- |              that used for submitting the OD: AR Disputes for       |
-- |          Sales Tax Reporting - Webcollect with the desirable        |
-- |              format of the user, and the                            |
-- |              default format is EXCEL and also does the necessary    |
-- |              validations and processing needed for the report R0536 |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |Draft 1  14-DEC-11      Maheswararao         Initial version         |
-- |                                                                     |
-- +=====================================================================+

-- +=====================================================================+
-- | Name :  XX_AR_WC_DISPUTES_TAX_PKG                                   |
-- | Description : The procedure will submit the OD: AR Disputes for     |
-- |           Sales Tax Reporting - Webcollect                          |
-- | Parameters :  p_period_from, p_period_to                            |
-- | Returns :  x_err_buff,x_ret_code                                    |
-- +=====================================================================+
   PROCEDURE DISPUTES_SALES_TAX_PROC (
      x_err_buff      OUT      VARCHAR2
     ,x_ret_code      OUT      NUMBER
     ,p_period_from   IN       VARCHAR2
     ,p_period_to     IN       VARCHAR2
   )
   AS
      -- Local Variable declaration
      ln_request_id    NUMBER (15);
      lb_layout        BOOLEAN;
      lb_req_status    BOOLEAN;
      lc_status_code   VARCHAR2 (10);
      lc_phase         VARCHAR2 (50);
      lc_status        VARCHAR2 (50);
      lc_devphase      VARCHAR2 (50);
      lc_devstatus     VARCHAR2 (50);
      lc_message       VARCHAR2 (50);
   BEGIN
      lb_layout := fnd_request.add_layout ('XXFIN'
                                          ,'XXARDISPSALTAX'
                                          ,'en'
                                          ,'US'
                                          ,'EXCEL'
                                          );
      ln_request_id := FND_REQUEST.SUBMIT_REQUEST ('XXFIN'
                                                  ,'XXARDISPSALTAX'
                                                  ,NULL
                                                  ,NULL
                                                  ,FALSE
                                                  ,p_period_from
                                                  ,p_period_to
                                                  );
      COMMIT;
      lb_req_status :=
         FND_CONCURRENT.WAIT_FOR_REQUEST (request_id      => ln_request_id
                                         ,INTERVAL        => '2'
                                         ,max_wait        => ''
                                         ,phase           => lc_phase
                                         ,status          => lc_status
                                         ,dev_phase       => lc_devphase
                                         ,dev_status      => lc_devstatus
                                         ,MESSAGE         => lc_message
                                         );

      IF ln_request_id <> 0
      THEN
         FND_FILE.PUT_LINE (FND_FILE.OUTPUT, 'The report has been submitted and the request id is: ' || ln_request_id);

         IF lc_devstatus = 'E'
         THEN
            x_err_buff := 'PROGRAM COMPLETED IN ERROR';
            x_ret_code := 2;
         ELSIF lc_devstatus = 'G'
         THEN
            x_err_buff := 'PROGRAM COMPLETED IN WARNING';
            x_ret_code := 1;
         ELSE
            x_err_buff := 'PROGRAM COMPLETED NORMAL';
            x_ret_code := 0;
         END IF;
      ELSE
         FND_FILE.PUT_LINE (FND_FILE.OUTPUT, 'The report did not get submitted');
      END IF;
   END DISPUTES_SALES_TAX_PROC;
END XX_AR_WC_DISPUTES_TAX_PKG;
/