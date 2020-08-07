SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY xx_ar_subscriptions_util_pkg
AS
-- +=========================================================================================+
-- |  Office Depot                                                                           |
-- +=========================================================================================+
-- |  Name:  XX_AR_SUBSCRIPTIONS_UTIL_PKG                                                      |
-- |                                                                                         |
-- |  Description:  This package body is used for Reporting Purposes                         |
-- |                                                                                         |
-- |  Change Record:                                                                         |
-- +=========================================================================================+
-- | Version     Date         Author              Remarks                                    |
-- | =========   ===========  =============       ===========================================|
-- | 1.0         09-AUG-2018  Punit Gupta         Added Function for the Report              |
-- |                                              OD: Subscription Billing Auth              |
-- |                                              Failures Report as per NAIT-50736          |
-- +=========================================================================================+

  /*******************************************
  *  Function to fetch the Subscription Errors
  ********************************************/
  FUNCTION xx_ar_subscr_errors(p_contract_number IN VARCHAR2,
                               p_contract_id IN NUMBER,
                               p_billing_sequence_number IN NUMBER)
  RETURN VARCHAR2
  IS
      lc_error_msg xx_ar_subscriptions_error.error_message%TYPE;
	  
    BEGIN  
	   lc_error_msg := NULL;
      BEGIN
		SELECT NVL(SUBSTR(TO_CHAR(XASP.response_data),INSTR(TO_CHAR(XASP.response_data),'message',-1)+10,INSTR(SUBSTR(TO_CHAR(XASP.response_data),INSTR(TO_CHAR(XASP.response_data),'message',-1)+13),'authCode')-1),TO_CHAR(XASP.response_data))
		INTO  lc_error_msg
		FROM  xx_ar_subscription_payloads XASP
		WHERE XASP.contract_number = p_contract_number
		AND   XASP.billing_sequence_number = p_billing_sequence_number
		AND   XASP.source = 'xx_ar_subscriptions_mt_pkg.process_authorization'
		AND   XASP.creation_date IN (SELECT MAX(creation_date)
									 FROM xx_ar_subscription_payloads XASP1
									 WHERE XASP1.contract_number = XASP.contract_number
									 AND XASP1.source = XASP.source
									);
      EXCEPTION
       WHEN NO_DATA_FOUND 
	   THEN
         BEGIN
			 SELECT NVL(SUBSTR(XASE.error_message,INSTR(TO_CHAR(XASE.error_message),'ACTION')+7,INSTR(SUBSTR(XASE.error_message,INSTR(TO_CHAR(XASE.error_message),'ACTION')+3),'ERROR')),XASE.error_message)
			 INTO  lc_error_msg
			 FROM  xx_ar_subscriptions_error XASE
			 WHERE XASE.contract_id = p_contract_id
			 AND   XASE.billing_sequence_number = p_billing_sequence_number
			 AND   XASE.creation_date IN (SELECT MAX(creation_date)
										  FROM  xx_ar_subscriptions_error XASE1
										  WHERE XASE1.contract_id = XASE.contract_id
										  AND   XASE1.billing_sequence_number = XASE.billing_sequence_number
										 );
  	     EXCEPTION
          WHEN NO_DATA_FOUND 
		  THEN
		      lc_error_msg := NULL;
	     END;
    END;
   RETURN lc_error_msg;
  END xx_ar_subscr_errors;

END xx_ar_subscriptions_util_pkg;
/