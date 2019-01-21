
SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                  Office Depot - Project Simplify						|
-- +============================================================================================+
-- | Name        : XXCDH_GET_AGING_DETAILS.pkb                                                  |
-- | Description : SFDC Conversion                                                              |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        08/15/2011       Devendra Petkar        Initial version                          |
-- |1.1        12/30/2015       Vasu Raparla           Removed Schema References for R.12.2     |
-- +============================================================================================+


CREATE OR REPLACE
PACKAGE BODY xxcdh_get_aging_details AS
  -- +======================================================================+
  -- | Name        : xxcdh_get_aging_details				    |
  -- | Author      :			                                    |
  -- | Description : This package is used to get			    |
  -- | 		    Aging details at the customer level	for 360degree	    |
  -- |									    |
  -- | Date        : August 15, 2011 --> New Version Started		    |
  -- | 08/15/2011  :  							    |
  -- +======================================================================+
  -- +======================================================================+

  PROCEDURE get_aging_details
      (   p_orig_system_reference             IN hz_cust_accounts.orig_system_reference%TYPE,
          x_AGING_CURRENT             OUT NOCOPY NUMBER,
          x_AGING_1_30_DAYS_PAST_DUE     OUT NOCOPY NUMBER,
          x_AGING_31_60_DAYS_PAST_DUE        OUT NOCOPY NUMBER,
          x_AGING_61_90_DAYS_PAST_DUE          OUT NOCOPY NUMBER,
	  x_AGING_90_MORE_DAYS_PAST_DUE		OUT NOCOPY NUMBER,
          x_return_Status           OUT NOCOPY VARCHAR2,
          x_msg_data                OUT NOCOPY VARCHAR2
      ) AS
  BEGIN
    BEGIN
      x_msg_data := null;
      x_return_status := 'SUCCESS';

--      x_AGING_CURRENT :=0;
--     x_AGING_1_30_DAYS_PAST_DUE :=0;
--    x_AGING_31_60_DAYS_PAST_DUE :=0;
--    x_AGING_61_90_DAYS_PAST_DUE :=0;
--   x_AGING_90_MORE_DAYS_PAST_DUE :=0;



	SELECT SUM(CASE WHEN sysdate - due_date >=-999 and sysdate - due_date<=0
                     THEN amount_due_remaining ELSE 0 END)
               ,SUM(CASE WHEN sysdate - due_date >=1 and sysdate - due_date<=30
                         THEN amount_due_remaining ELSE 0 END)
               ,SUM(CASE WHEN sysdate - due_date >=31 and sysdate - due_date<=60
                         THEN amount_due_remaining ELSE 0 END)
               ,SUM(CASE WHEN sysdate - due_date > =61 and sysdate - due_date<=90
                         THEN amount_due_remaining ELSE 0 END)
               ,SUM(CASE WHEN sysdate - due_date >=91 and sysdate - due_date <=9999
                         THEN amount_due_remaining ELSE 0 END)
		INTO x_AGING_CURRENT, x_AGING_1_30_DAYS_PAST_DUE, x_AGING_31_60_DAYS_PAST_DUE, x_AGING_61_90_DAYS_PAST_DUE, x_AGING_90_MORE_DAYS_PAST_DUE
	FROM ar_payment_schedules_all
	WHERE
		--status='OP'	AND
		customer_id IN (SELECT cust_account_id
					FROM hz_cust_accounts
						WHERE orig_system_reference = p_orig_system_reference)
		GROUP BY customer_id;


--	      SELECT
--               SUM(CASE WHEN days_due >=-999 and days_due<=0
--                     THEN amount_due ELSE 0 END)
--               ,SUM(CASE WHEN days_due >=1 and days_due<=30
--                         THEN amount_due ELSE 0 END)
--               ,SUM(CASE WHEN days_due >=31 and days_due<=60
--                         THEN amount_due ELSE 0 END)
--               ,SUM(CASE WHEN days_due > =61 and days_due<=90
--                         THEN amount_due ELSE 0 END)
--               ,SUM(CASE WHEN days_due >=91 and days_due <=9999
--                         THEN amount_due ELSE 0 END)
--INTO x_AGING_CURRENT, x_AGING_1_30_DAYS_PAST_DUE, x_AGING_31_60_DAYS_PAST_DUE, x_AGING_61_90_DAYS_PAST_DUE, x_AGING_90_MORE_DAYS_PAST_DUE
--         FROM  (SELECT  customer_id
--                       ,NVL(XX_AR_AGING_PKG.XX_AR_BAL_AMT_FUNC(payment_schedule_id,class,SYSDATE),0) amount_due
--                       ,TRUNC(SYSDATE)- due_date days_due
--                 FROM  XX_AR_OPEN_TRANS_ITM   APS
--                 WHERE customer_id = p_customer_id
--                )
--         GROUP BY customer_id;

    EXCEPTION
    WHEN NO_DATA_FOUND THEN
    x_msg_data := 'Orig_system_reference is not found in the system.';
    WHEN OTHERS THEN
      x_msg_data := 'Error getting in Orig_system_reference from ar_payment_schedules_all.'||
      ' SQL Code: '||SQLCODE||' '||SUBSTR(SQLERRM,1,100);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,x_msg_data||' SQL Code: '||SQLCODE||' '||SUBSTR(SQLERRM,1,100));
      FND_FILE.PUT_LINE(FND_FILE.LOG,x_msg_data||' SQL Code: '||SQLCODE||' '||SUBSTR(SQLERRM,1,100));
      x_return_status := 'ERROR';
    END;
  END get_aging_details;
-- +====================================================================+
END xxcdh_get_aging_details;
/
SHOW ERRORS;

EXIT;
