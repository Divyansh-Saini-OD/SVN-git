 -- +============================================================================================+
  -- |  Office Depot                                                                          	  |
  -- +============================================================================================+
  -- |  Name:  XXOD_AR_INV_UPDATE_CMNTS                                                           |
  -- |                                                                                            |
  -- |  Description:  This SCRIPT Update and Trims the Comments of  all OMX ODN invoices          | 
  -- |                						        		                                      |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         13-MAR-2017  Punit Gupta      Initial version                                  |
  -- +============================================================================================+
  
UPDATE AR.RA_CUSTOMER_TRX_ALL
SET COMMENTS =  TRIM(COMMENTS)
WHERE customer_trx_id IN (SELECT DISTINCT customer_trx_id
	                      FROM   xxfin.xxod_omx_cnv_ar_trx_stg STG, ar.ra_customer_trx_all RCT
                          WHERE RCT.TRX_NUMBER = STG.INV_NO
                          AND STG.process_flag = 4
						  );
COMMIT;   

SHOW ERRORS;

EXIT;