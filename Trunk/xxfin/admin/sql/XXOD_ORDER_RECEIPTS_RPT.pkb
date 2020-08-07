create or replace
PACKAGE BODY      XXOD_ORDER_RECEIPTS_RPT
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       Oracle GSD                                    |
-- +=====================================================================+
-- | Name : XXOD_ORDER_RECEIPTS_RPT                                      |
-- | Defect# : 15034                                                     |
-- | Description : This package houses the report submission procedure   |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |Draft 1A  31-JAN-12     Saikumar Reddy       Initial version         |
-- |      1B  02-JUN-14     Pravedra Lohiya      Defect 29050            |
-- |      1C  02-Feb-16     Avinash  Baddam      Defect#37204–Masterpass |  
-- +=====================================================================+

-- +=====================================================================+
-- | Name :  ORDER_RECEPTS_PRC                                           |
-- | Description : This procedure will submit the detail and summary     |
-- |               reports for defect# 15034                             |
-- | Parameters  :           						 |
-- | Returns     : x_err_buff,x_ret_code                                 |
-- +=====================================================================+

PROCEDURE ORDER_RECEPTS_PRC (
                             x_err_buff    OUT VARCHAR2
                            ,x_ret_code    OUT NUMBER
                            ,P_MODE        IN  VARCHAR2
							,P_HIDDEN	   IN  VARCHAR2				
              ,P_SEARCH_TYPE IN VARCHAR2         -- Added by P Lohiya For Defect 29050
              ,P_DUMMY1      IN VARCHAR2         -- Added by P Lohiya For Defect 29050
              ,P_DUMMY2      IN VARCHAR2         -- Added by P Lohiya For Defect 29050
							,P_RECEIPT_DATE_FROM IN  VARCHAR2
							,P_RECEIPT_DATE_TO IN  VARCHAR2
              ,P_CREATION_DATE_FROM IN  VARCHAR2  -- Added by P Lohiya For Defect 29050
              ,P_CREATION_DATE_TO IN  VARCHAR2    -- Added by P Lohiya For Defect 29050
							,P_CARD_TYPE IN  VARCHAR2
							,P_RECEIPT_STATUS IN  VARCHAR2
							,P_MATCHED_STATUS IN  VARCHAR2
							,P_REMITTED_STATUS IN  VARCHAR2
							,P_STORE_NUMBER_FROM IN  VARCHAR2
							,P_STORE_NUMBER_TO IN  VARCHAR2
							,P_WALLET_TYPE     IN  VARCHAR2
                            )
AS

 ln_srequest_id NUMBER(15);

 lb_sreq_status  BOOLEAN;
 lb_layout       BOOLEAN;

 lc_sphase       VARCHAR2(50);
 lc_sstatus      VARCHAR2(50);
 lc_sdevphase    VARCHAR2(50);
 lc_sdevstatus   VARCHAR2(50);
 lc_smessage     VARCHAR2(50);


 ld_date         DATE;
 EX_SUBMIT       EXCEPTION;

BEGIN

      lb_layout := FND_REQUEST.ADD_LAYOUT(
                                          'XXFIN'
                                         ,'XXODORDERRECEIPTSRPT'
                                         ,'en'
                                         ,'US'
                                         ,'EXCEL'
                                         );

      ln_srequest_id := FND_REQUEST.SUBMIT_REQUEST(
                                                   'XXFIN'
                                                  ,'XXODORDERRECEIPTSRPT'
                                                  ,NULL
                                                  ,TO_CHAR(SYSDATE,'DD-MON-YY HH24:MM:SS')
                                                  ,FALSE
                                                  ,P_MODE
						  ,P_HIDDEN
                                                  ,to_date(P_RECEIPT_DATE_FROM,'DD-MON-YYYY')
                                                  ,to_date(P_RECEIPT_DATE_TO, 'DD-MON-YYYY')
                                                  ,to_date(P_CREATION_DATE_FROM,'DD-MON-YYYY') -- Added by P Lohiya For Defect 29050
                                                  ,to_date(P_CREATION_DATE_TO,'DD-MON-YYYY')   
                                                  ,P_CARD_TYPE
                                                  ,P_RECEIPT_STATUS
                                                  ,P_MATCHED_STATUS
                                                  ,P_REMITTED_STATUS
                                                  ,P_STORE_NUMBER_FROM
                                                  ,P_STORE_NUMBER_TO
                                                  ,P_WALLET_TYPE
                                                  );
      COMMIT;


      lb_sreq_status := FND_CONCURRENT.WAIT_FOR_REQUEST(
                                                        request_id => ln_srequest_id
                                                       ,interval   => '2'
                                                       ,max_wait   => NULL
                                                       ,phase      => lc_sphase
                                                       ,status     => lc_sstatus
                                                       ,dev_phase  => lc_sdevphase
                                                       ,dev_status => lc_sdevstatus
                                                       ,message    => lc_smessage
                                                       );


              IF (UPPER(lc_sstatus)) = 'ERROR'  THEN

                  x_err_buff := 'The Report Completed in ERROR';
                  x_ret_code := 2;

              ELSIF (UPPER(lc_sstatus)) = 'WARNING'  THEN

                  x_err_buff := 'The Report Completed in WARNING';
                  x_ret_code := 1;

              ELSE

                  x_err_buff := 'The Report Completion NORMAL';
                  x_ret_code := 0;

              END IF;   

END ORDER_RECEPTS_PRC;

END XXOD_ORDER_RECEIPTS_RPT;
/