SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET TERM ON

PROMPT Creating PACKAGE Body XX_CM_KEY_STORE_DEP_PKG
PROMPT Program exits IF the creation is not successful
WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE
PACKAGE BODY XX_CM_KEY_STORE_DEP_PKG
AS

-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name : XX_CM_KEY_STORE_DEP_PKG                                      |
-- | RICE ID :  R0537                                                    |
-- | Description :This package is the executable of the wrapper program  |
-- |              that used for submitting the OD: CM Keyed Store Deposit|
-- |              report with the desirable format of the user, and the  |
-- |              default format is EXCEL                                |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |Draft 1A  29-DEC-08      Manovinayak         Initial version         |
-- |                         Ayyappan                                    |
-- +=====================================================================+

-- +=====================================================================+
-- | Name :  XX_CM_KEY_STORE_DEP_PROC                                    |
-- | Description : The procedure will submit the OD: CM Keyed Store      |
-- |               Deposit report in the specified format                |
-- | Parameters :  p_date_from, p_date_to, p_bank_name, p_bank_branch,   |
-- |               p_bank_account, p_location, p_district, p_region      |
-- |               p_deposit_type, p_status_code                         |
-- | Returns :  x_err_buff,x_ret_code                                    |
-- +=====================================================================+

PROCEDURE XX_CM_KEY_STORE_DEP_PROC(
                                   x_err_buff      OUT VARCHAR2
                                  ,x_ret_code      OUT NUMBER
                                  ,p_date_from     IN  VARCHAR2
                                  ,p_date_to       IN  VARCHAR2
                                  ,p_bank_name     IN  VARCHAR2
                                  ,p_bank_branch   IN  VARCHAR2
                                  ,p_bank_account  IN  VARCHAR2
                                  ,p_location_from IN  VARCHAR2
                                  ,p_location_to   IN  VARCHAR2
                                  ,p_district      IN  VARCHAR2
                                  ,p_region        IN  VARCHAR2
                                  ,p_deposit_type  IN  VARCHAR2
                                  ,p_status_code   IN  VARCHAR2
                                  )
AS

  -- Local Variable declaration
   ln_request_id        NUMBER(15);
   lb_layout            BOOLEAN;
   lb_req_status        BOOLEAN;
   lc_status_code       VARCHAR2(10);
   lc_phase             VARCHAR2(50);
   lc_status            VARCHAR2(50);
   lc_devphase          VARCHAR2(50);
   lc_devstatus         VARCHAR2(50);
   lc_message           VARCHAR2(50);

BEGIN

  lb_layout := fnd_request.add_layout(
                                      'XXFIN'
                                     ,'XXCMKEYSTORDEP'
                                     ,'en'
                                     ,'US'
                                     ,'EXCEL'
                                     );

  ln_request_id := FND_REQUEST.SUBMIT_REQUEST(
                                              'XXFIN'
                                             ,'XXCMKEYSTORDEP'
                                             ,NULL
                                             ,NULL
                                             ,FALSE
                                             ,p_date_from
                                             ,p_date_to
                                             ,p_bank_name
                                             ,p_bank_branch
                                             ,p_bank_account
                                             ,p_location_from
                                             ,p_location_to
                                             ,p_district
                                             ,p_region
                                             ,p_deposit_type
                                             ,p_status_code
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

  ELSE FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The report did not get submitted');

  END IF;

END XX_CM_KEY_STORE_DEP_PROC;

END XX_CM_KEY_STORE_DEP_PKG;
/
SHO ERR;