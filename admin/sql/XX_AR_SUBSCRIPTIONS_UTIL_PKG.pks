SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace PACKAGE xx_ar_subscriptions_util_pkg 
AS
-- +===============================================================================+
-- |  Office Depot                                                                 |
-- +===============================================================================+
-- |  Name:  XX_AR_SUBSCRIPTIONS_UTIL_PKG                                          |
-- |                                                                               |
-- |  Description:  This package body is used for Reporting Purposes               |
-- |                                                                               |
-- |  Change Record:                                                               |
-- +===============================================================================+
-- | Version     Date         Author              Remarks                          |
-- | =========   ===========  =============       =================================|
-- | 1.0         09-AUG-2018  Punit Gupta         Added Function for the Report    |
-- |                                              OD: Subscription Billing Auth    |
-- |                                              Failures Report as per NAIT-50736|
-- +===============================================================================+                                                                         
  
  /******
  * MAIN
  ******/
  					 
  /*******************************************
  *  Function to fetch the Subscription Errors
  ********************************************/
  FUNCTION xx_ar_subscr_errors(p_contract_number IN VARCHAR2,
                               p_contract_id IN NUMBER,
                               p_billing_sequence_number IN NUMBER)
							   RETURN VARCHAR2;
								 
END;
/
