create or replace PACKAGE XX_FIN_VPS_DAYS_LATE
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                          	  |
  -- +============================================================================================+
  -- |  Name:  XX_FIN_VPS_DAYS_LATE                                                     	        |
  -- |                                                                                            |
  -- |  Description:  This package is used by datawarehouse team to get days late.        	      |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         07-AUG-2017  Thejaswini Rajula    Initial version                              |
  -- +============================================================================================+
Function AR_DAYS_LATE ( p_cash_receipt_id IN NUMBER )
   RETURN NUMBER;

END XX_FIN_VPS_DAYS_LATE;
/